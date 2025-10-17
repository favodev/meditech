import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GetSignedUrlConfig, Storage } from '@google-cloud/storage';
import { join } from 'path';

@Injectable()
export class StorageService {
  private readonly storage: Storage;
  private readonly bucketName: string;

  constructor(private readonly configService: ConfigService) {
    this.storage = new Storage({
      keyFilename: join(process.cwd(), 'gcp-credentials.json'),
    });

    this.bucketName = this.configService.get('GCS_BUCKET_NAME') as string;
  }

  async uploadFile(
    file: Express.Multer.File,
    destinationPath: string,
  ): Promise<string> {
    const bucket = this.storage.bucket(this.bucketName);
    const blob = bucket.file(destinationPath);

    const blobStream = blob.createWriteStream({
      resumable: false,
    });

    return new Promise((resolve, reject) => {
      blobStream.on('error', (err) => reject(err));
      blobStream.on('finish', () => {
        const publicUrl = `${destinationPath}`;
        resolve(publicUrl);
      });
      blobStream.end(file.buffer);
    });
  }

  async downloadFile(
    path: string,
    originalFileName: string,
    format: string,
    minutesToExpire: number = 15,
  ): Promise<string> {
    const options: GetSignedUrlConfig = {
      version: 'v4',
      action: 'read',
      expires: Date.now() + minutesToExpire * 60 * 1000,
      responseDisposition: `attachment; filename="${originalFileName}.${format}"`,
    };

    const [url] = await this.storage
      .bucket(this.bucketName)
      .file(path)
      .getSignedUrl(options);

    return url;
  }

  async openFile(path: string, minutesToExpire: number = 15): Promise<string> {
    const options: GetSignedUrlConfig = {
      version: 'v4',
      action: 'read',
      expires: Date.now() + minutesToExpire * 60 * 1000,
    };

    const [url] = await this.storage
      .bucket(this.bucketName)
      .file(path)
      .getSignedUrl(options);

    return url;
  }
}
