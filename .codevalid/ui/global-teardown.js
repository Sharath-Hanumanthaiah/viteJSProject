import { uploadRecordingsToS3 } from "./helpers/upload-recordings-to-s3.js";

export default async function globalTeardown() {
  await uploadRecordingsToS3();
}
