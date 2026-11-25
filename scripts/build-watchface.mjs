import { buildOptimizedProject, getConfig } from "@markw65/monkeyc-optimizer";
import { optimizeProgram } from "@markw65/monkeyc-optimizer/sdk-util.js";
import { resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const [sdkPath, developerKeyPath, output, device] = process.argv.slice(2);
const workspace = fileURLToPath(new URL("../", import.meta.url));
const buildDir = resolve(workspace, "bin", "build", device ?? "release");
const options = await getConfig({
    workspace,
    sdkPath: resolve(sdkPath) + sep,
    developerKeyPath: resolve(developerKeyPath),
    jungleFiles: resolve(workspace, "monkey.jungle"),
    buildDir,
    outputPath: resolve(buildDir, "optimized"),
    program: resolve(buildDir, "Segment34Plus" + (device ? ".prg" : ".iq")),
    ignore_settings_files: true,
    compilerOptions: "--no-gen-styles",
    // Garmin's informative checker can reject equivalent control flow in generated source.
    typeCheckLevel: "Off",
    releaseBuild: true,
    testBuild: false,
    compilerWarnings: false
});
const { program } = await buildOptimizedProject(device ?? null, options);
await optimizeProgram(program, options.developerKeyPath, resolve(output), options);
console.log("Built " + output);
