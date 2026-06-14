import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const FLOWS_DIR = path.join(__dirname, "..", "recordings", "flows");

export class ExecutionRecorder {
  constructor(acceptanceCriteriaId, testTitle) {
    this.acceptanceCriteriaId = acceptanceCriteriaId;
    this.testTitle = testTitle;
    this.steps = [];
    this.startedAt = new Date().toISOString();
  }

  record(action, detail = {}) {
    this.steps.push({
      step: this.steps.length + 1,
      action,
      detail,
      timestamp: new Date().toISOString(),
    });
  }

  async save(testInfo) {
    fs.mkdirSync(FLOWS_DIR, { recursive: true });

    const safeTitle = this.testTitle.replace(/[^\w-]+/g, "_");
    const flowPath = path.join(
      FLOWS_DIR,
      `${this.acceptanceCriteriaId}-${safeTitle}.json`
    );

    const payload = {
      acceptanceCriteriaId: this.acceptanceCriteriaId,
      testTitle: this.testTitle,
      startedAt: this.startedAt,
      completedAt: new Date().toISOString(),
      status: testInfo.status,
      steps: this.steps,
      recording: {
        video: testInfo.outputDir
          ? path.join(testInfo.outputDir, "video.webm")
          : null,
        trace: testInfo.outputDir
          ? path.join(testInfo.outputDir, "trace.zip")
          : null,
      },
    };

    fs.writeFileSync(flowPath, JSON.stringify(payload, null, 2));
    return flowPath;
  }
}
