

## CI & Environment Vars
> <img width="500" alt="image" src="https://github.com/Liampronan/workout-playlist/assets/4316904/396be58b-4738-4a0d-8500-0ead577c2fce">

- We're using Xcode Cloud to build the app.

 > <img width="500" alt="Environment Vars Build Step" src="https://github.com/Liampronan/workout-playlist/assets/4316904/fb4cf13e-7a58-4326-8080-eb7b77bd17da">
 - As part of the build process, we create a `config.json` file from environmental variables that are passed in from the Xcode Cloud setup. This build step is defined in [`ci_pre_xcodebuild.sh`](./ci_scripts/ci_pre_xcodebuild.sh).
   - This `ci_pre_xcodebuild.sh` filename is defined by Xcode Cloud.  It is one of [three predefined build scripts by the Xcode Cloud build process](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts)
   - If you're building the app locally, you need a version of this file. It is not checked into this repo. Contact Liam if you need this.  

## Areas for improvement

### Front-end testing
- At this point, I'm just relying on manual app testing and preview-based testing. This is not super scalable but works for this initial app – I've been focused on building a solid architecture which has lead to a lot of foundational changes. 
- In my next app, I'll build using a core architecture with tests as a per-feature to-do. 
- I'm also looking at good solutions for on-device mocking via a dev menu – so a user can switch between prod and mocked data. I've used this pattern in the past and it works well. 
- I experimented with [emerge tools' snapshot testing'](https://www.emergetools.com/#snapshots) which I found nice for noting visual changes, but not super useful at an early stage. I would love to see a tool like 

### Design System
- Currently, UI things are too ad-hoc. This is partially a product of me learning SwiftUI as I go as well as deciding to cut this project short before shipping due to Spotify API review issues – it does not make a ton of sense for me to refactor into a design system at this point.  
- On my next project, I'll focus more on having simple design components to avoid things like adhoc/fixed view/text sizes.   
