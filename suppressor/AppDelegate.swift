//
//  AppDelegate.swift
//  suppressor
//
//  Created by Andrew Clunis on 2014-11-01.
//  Copyright (c) 2014 Andrew Clunis. All rights reserved.
//

import Cocoa

import CoreAudio

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // https://github.com/InerziaSoft/ISSoundAdditions/blob/master/ISSoundAdditions.m
    
    // http://stackoverflow.com/questions/11041335/how-do-you-set-the-input-level-gain-on-the-built-in-input-osx-core-audio-au
    
    // https://developer.apple.com/library/mac/qa/qa1016/_index.html DEPRECATED (without any note, thanks a lot Apple)
    
    // https://developer.apple.com/library/mac/technotes/tn2223/_index.html SEEMS ACTUALLY LEGIT

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        
        
        // var poop = NSEvent();
        
        NSEvent.addGlobalMonitorForEventsMatchingMask(NSEventMask.KeyDownMask, { (NSEvent) -> Void in
            // poop smeeee
            NSLog("It's muting time!");
            
            var error : OSStatus = 0;
            
            // Using CoreAudio with Swift has some rough edges.  There's a frequent type disagreement between Int and UInt32 constants and other int paramters.
            
            // Get the default audio device:
            // TODO: these UInt32 casts are grody.  API bug (the contants are Ints whereas the field types are UInt) or is there a better way to do this?
            var poop = AudioObjectPropertyAddress(mSelector:  UInt32(kAudioHardwarePropertyDefaultOutputDevice), mScope: UInt32(kAudioObjectPropertyScopeGlobal), mElement: UInt32(kAudioObjectPropertyElementMaster));
            
            
            
            // And determine that it exists:
            // 0 is falsy on the old Boolean type
            if(AudioObjectHasProperty(UInt32(kAudioObjectSystemObject), &poop) == 0) {
                NSLog("NO DEFAULT AUDIO INPUT?!");
                return;
            }
            
            var inputDevice : AudioDeviceID = 0;
            
            // why does Apple make us pass this size in?  surely they already know it? (is the idea to allow
            // passing in different types?)
            var audioDeviceIdSize = UInt32(sizeof(AudioDeviceID));
            
            if(AudioObjectGetPropertyData(UInt32(kAudioObjectSystemObject), &poop, 0, nil, &audioDeviceIdSize, &inputDevice) != 0) {
                // weird, OS X said it was there, and yet, it asplode
                NSLog("FUCKFARTS, CANNOT GET YE DEFAULT INPUT DEVICE");
                return;
            }

            // TODO fuck, how do I enumerate the channels?!
            var channel = 2;
            
            //var channelAddress = AudioObjectPropertyAddress(mSelector: UInt32(kAudioObjectPropertyElementName), mScope: <#AudioObjectPropertyScope#>, mElement: <#AudioObjectPropertyElement#>)
            
            // now, build a PropertyAddress that describes the input gain control on it
            var inputVolumeControlAddress = AudioObjectPropertyAddress(mSelector: UInt32(kAudioDevicePropertyVolumeScalar), mScope: UInt32(kAudioDevicePropertyScopeInput), mElement: UInt32(channel));

            var currentVolume: Float32 = 0;
            var volumeSize = UInt32(sizeof(Float32));

            error = AudioObjectGetPropertyData(inputDevice, &inputVolumeControlAddress, 0, nil, &volumeSize, &currentVolume);
            if(error != 0) {
                if (kAudioHardwareUnknownPropertyError == Int(error)) {
                    // kAudioHardwareUnknownPropertyError.
                    NSLog("Core Audio reports 'unknown property' for the volume control.");
                } else {
                    // var prettyError = NSError(domain: NSOSStatusErrorDomain!, code: Int(error), userInfo: nil);
                    NSLog("ULTRAFARTS, unable to get ye current volume setting, unknown reason: %d", error);
                }
                return;
            }
            
            NSLog("WOO, got current volume: %f", currentVolume);
            
            
            // Now, to see if the gain is settable on it:
            
            
        });
        
        
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func osStatusToString(status: OSStatus) -> String {
        return "asdfsaf";
    }


}
