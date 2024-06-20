

### CI & Environment Vars
> <img width="500" alt="image" src="https://github.com/Liampronan/workout-playlist/assets/4316904/396be58b-4738-4a0d-8500-0ead577c2fce">

- We're using Xcode Cloud to build the app.

 > <img width="500" alt="Environment Vars Build Step" src="https://github.com/Liampronan/workout-playlist/assets/4316904/fb4cf13e-7a58-4326-8080-eb7b77bd17da">
 - As part of the build process, we create a `config.json` file from environmental variables that are passed in from the Xcode Cloud setup. This build step is defined in [`ci_pre_xcodebuild.sh`](./ci_scripts/ci_pre_xcodebuild.sh).
   - This `ci_pre_xcodebuild.sh` filename is defined by Xcode Cloud.  It is one of [three predefined build scripts by the Xcode Cloud build process](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts)
   - If you're building the app locally, you need a version of this file. It is not checked into this repo. Contact Liam if you need this.  
