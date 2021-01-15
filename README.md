# CommunicationDemo
Demo communication app between iPhone and Apple Watch and MVP+C architecture setup

App creates and runs WCSession communication between iPhone and Apple Watch devices
There are 2 ways of cummunication:
1) simple tapping on button to send message
2) scheduled timers which send messages

App is running in background state also using HKWorkout API.

Each delegate method has logging functionality for it's state / event.

We can look at logs by sending them to an e-mail using same functionality as Legacy app

Dependencies: 
We have only 1 dependendy: Zip which is added using Swift Package Manager
