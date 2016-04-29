<img src="http://i.imgur.com/Tyx3dLj.png" alt="cargi logo" width="300">

Many tools in our lives are personalized, and we should expect the same things from our cars, considering the amount of time we spend in them. Drivers have varying skills and habits: some might prefer a safe driver mode which allows them to easily switch lanes, guides them into a parking spot, and finds roads where there are fewer cars.  Others might want the radio blasting and mood lighting as they speed down the highway, or want to automatically play their favorite morning radio show on their way to work. We’re really excited to make the car experience something that is more than just about getting from one place to another - the car should feel like an extension of yourself where everything is customized to perfectly meet your needs.

# Getting started:
To run the iOS app, you must import the GoogleMaps framework, which is stored in our Google Drive `6 - Software Demo` due to its large size. Place the GoogleMaps.framework file in `iOS > CargiApp > Pods > GoogleMaps > Frameworks`.

**Important**: Do not use `.xcodeproject` file to open Xcode; use `iOS > CargiApp > CargiApp.xcworkspace` instead.

# Development Workflow:
1. For every feature or bug fix needed on the Cargi app, open up an issue first.
2. Assign yourself, or another team member to the issue, with proper labels (high/low priority, etc).
3. When done with an issue, commit and push your code, and close the issue. Remember to `git pull` first to get the current changes.

#### Note regarding branches
- When working on a feature that is still in the development phase, *always* work on the `dev` branch.
- If the feature is fully-working, push to the `master` branch.
- If the feature has been thoroughly tested and is ready for deployment, push to the `deploy` branch.

### Other APIs/SDKs
- Maya built an API for finding cheap gas: https://github.com/mayanb/gaspriceapi
- Nuance SpeechKit for speech recognition and text-to-speech
- 

<!--# Development Milestones:-->
<!--- [x] Navigation (Apple/Google) to the next event's location -->
<!--- [x] Show route with directions from current location to destination-->
<!--- [x] Message ETA / Calling friends using event details-->
<!--- [x] Polished UI-->
<!--- [x] Easy access to music control-->

<!--# Completed Steps:-->
<!--- [x] Set up Google Maps view and basic Google Places search-->
<!--- [x] Compute ETA given origin & destination-->
<!--- [x] Parse events from Apple Calendar-->
<!--- [x] Parse reminders from Reminders app-->
<!--- [x] Set up messages and calling through Cargi-->
<!--- [x] Set up local notifications-->
<!--- [ ] [blocked] Experiment with bluetooth connection and automatic app launching (3/8 received iBeacon from Michael and Robert, but need to obtain arduino)-->
<!--- [x] Redirect to Apple/Google Maps with destination set up using deep linking-->
<!--- [x] Create and send text messages or iMessages to others users-->
<!--- [x] Dashboard UI for easy access to Messages / Phone Calling-->
<!--- [ ] [blocked] Access message and calling history ... and it isn't possible-->
<!--- [x] Add Spotify to the dashboard-->
<!--- [x] Iterate on user interface prototypes (what happens when there are no calendar events?) -->
<!--- [x] Retrieving contact information from calendar events (limited)-->
<!--- [x] Compute ETA given current location & destination-->
<!--- [x] Use origami to design the user interface-->
<!--- [x] Draw route on the map using Google Maps Directions API-->
<!--- [ ] Need to parse JSON in a clean way: cleanly parse using built-in library, or import some third-party library (SwiftyJSON)-->
<!--- [ ] Implement smart filtering of contacts (back end)-->
<!--- [ ] Implement smart filtering of contacts (front end - user interface)-->

