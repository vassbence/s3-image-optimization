import sharp from "sharp";
import {
  S3Client,
  GetObjectCommand,
  PutObjectCommand,
} from "@aws-sdk/client-s3";
import type { APIGatewayProxyEventV2 } from "aws-lambda";

type SUPPORTED_FORMAT =
  | "gif"
  | "avif"
  | "webp"
  | "png"
  | "svg"
  | "jpeg"
  | "jpg";

const s3Client = new S3Client({});

async function tryGetImageFromS3(key: string) {
  try {
    const { Body } = await s3Client.send(
      new GetObjectCommand({
        Bucket: process.env.ORIGINAL_IMAGES_BUCKET_NAME,
        Key: key,
      })
    );

    if (!Body) {
      return null;
    }

    return {
      byteArray: await Body.transformToByteArray(),
    };
  } catch {
    return null;
  }
}

export const handler = async (event: APIGatewayProxyEventV2) => {
  const key = event.rawPath.split("/")[1];
  const format = event.rawPath.split("/")[2] as SUPPORTED_FORMAT;
  const width = parseInt(event.rawPath.split("/")[3]);

  const image = await tryGetImageFromS3(key);

  if (!image) {
    return {
      statusCode: 404,
    };
  }

  const optimizedImageBuffer = await sharp(image.byteArray)
    .resize({ width, withoutEnlargement: true })
    .toFormat(format)
    .toBuffer();

  const optimizedBucketKey = `${key}/${format}/${width}`;

  await s3Client.send(
    new PutObjectCommand({
      Bucket: process.env.OPTIMIZED_IMAGES_BUCKET_NAME,
      Key: optimizedBucketKey,
      Body: optimizedImageBuffer,
      ContentType: `image/${format}`,
      ACL: "public-read",
    })
  );

  if (optimizedImageBuffer.byteLength > 6 * 1_000_000) {
    return {
      statusCode: 307,
      headers: {
        Location: `https://${process.env.OPTIMIZED_IMAGES_BUCKET_URL}/${optimizedBucketKey}`,
      },
    };
  }

  return {
    statusCode: 200,
    body: optimizedImageBuffer.toString("base64"),
    isBase64Encoded: true,
    headers: {
      "Content-Type": `image/${format}`,
    },
  };
};
