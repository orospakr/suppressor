//
//  AppDelegate.swift
//  suppressor
//
//  Created by Andrew Clunis on 2014-11-01.
//  Copyright (c) 2014 Andrew Clunis. All rights reserved.
//

import Cocoa

import CoreAudio

func osStatusToString(status: OSStatus) -> String {
    // this sucks. lol objc API
    
    switch Int(status) {
    case kAudioHardwareUnknownPropertyError:
        return "Unknown property.";
    default:
        return String(format: "Unknown error: %d", status);
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    
    func keystrokeSignal() -> RACSignal {
        return RACSignal.createSignal({ (subscriber) -> RACDisposable! in
            NSLog("Keyboard listener created!")
            
            // TODO: how do I tear this listener down when the listener is no longer needed? Does ARC do it for me?
            NSEvent.addGlobalMonitorForEventsMatchingMask(NSEventMask.KeyDownMask, handler: { (event) -> Void in
                subscriber.sendNext(event);
            })
            return nil
        })
    }
    
    // typedef RACStream * (^RACStreamBindBlock)(id value, BOOL *stop);
    
    // a func that matches that declaration:
//    func everyOtherEvent(value: AnyObject!, stop: ObjCBool) -> RACStream! {
//        return nil;
//    }
//    

    func everyOtherEvent() -> RACStreamBindBlock {
        var poop = RACStream();
        var clazz = self.superclass!;
        
        var flippy = false;
        
        return {
            (id: AnyObject!, stop: UnsafeMutablePointer<ObjCBool>) -> RACStream! in
            
            stop.memory = false;
        
            // can't use swift's "is", because apparently you have to use a class literal with that, not a variable of a class
            if(!id.isKindOfClass(clazz)) {
                // TODO: once ReactiveCocoa gains a strongly-typed Swift API, this sort of silliness can go away :D
                fatalError("everyOtherEvent's closure received an event of a differen type that itself.  It is a: " + id.superclass.debugDescription)
            }
            
            var str = "Fdsaf"
            var newStream : RACStream
            if(flippy) {
                newStream = RACSignal.`return`(str)
            } else {
                newStream = RACSignal.empty()
            }
            flippy = !flippy
            return newStream
        }
    }
    
    // https://github.com/InerziaSoft/ISSoundAdditions/blob/master/ISSoundAdditions.m
    
    // http://stackoverflow.com/questions/11041335/how-do-you-set-the-input-level-gain-on-the-built-in-input-osx-core-audio-au
    
    // https://developer.apple.com/library/mac/qa/qa1016/_index.html DEPRECATED (without any note, thanks a lot Apple)
    
    // https://developer.apple.com/library/mac/technotes/tn2223/_index.html SEEMS ACTUALLY LEGIT
    
    // http://www.slideshare.net/colineberhardt/reactive-cocoa-made-simple-with-swift

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        
        // A note about typing and RACSignals under Swift one bummer about RAC seems to be that the signals themselves do not expose compile-time type information about what they emit, so listeners
        // are expected to cast.  Probably a hangover from Objective-C.  The workarounds online either have you do a manual cast *or* a generic wrapper method which still just casts (even though it does infer from the arguments of the *receiver* of the stream, which is of course the wrong direction).  Presumably RAC3 (with official Swift support) will have a better solution for this.  I can't see any reason why it couldn't...
        keystrokeSignal().subscribeNext { (untypedsadness: AnyObject!) -> Void in
            NSLog("YUMMY KEYSTROKES")
        }
        
        // var poop = NSEvent();
        
        var wat = keystrokeSignal().bind(everyOtherEvent).subscribeNext { (woot: AnyObject!) -> Void in
            NSLog("VOIP \(woot).");
        }
        
        NSEvent.addGlobalMonitorForEventsMatchingMask(NSEventMask.KeyDownMask, { (NSEvent) -> Void in
            // poop smeeee
            NSLog("It's muting time!");
            
            var error : OSStatus = 0;
            
            // Using CoreAudio with Swift has some rough edges.  There's a frequent type disagreement between Int and UInt32 constants and other int paramters.
            
            // Get the default audio device:
            // TODO: these UInt32 casts are grody.  API bug (the contants are Ints whereas the field types are UInt) or is there a better way to do this?
            var poop = AudioObjectPropertyAddress(mSelector:  UInt32(kAudioHardwarePropertyDefaultInputDevice), mScope: UInt32(kAudioObjectPropertyScopeGlobal), mElement: UInt32(kAudioObjectPropertyElementMaster));
            
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

            var channelsAddress = AudioObjectPropertyAddress(
                mSelector: UInt32(kAudioDevicePropertyPreferredChannelsForStereo),
                mScope: UInt32(kAudioDevicePropertyScopeInput),
                mElement: UInt32(kAudioObjectPropertyElementWildcard))
            
            // first, let's find out how many there are
            
            var channelsCount : UInt32 = 0;
            
            error = AudioObjectGetPropertyDataSize(inputDevice, &channelsAddress, 0, nil, &channelsCount);
            if(error != 0) {
                NSLog("Unknown error retrieving number of channels on input device: \(osStatusToString(error))");
                return;
            }
            
            NSLog("You have %d channels on your input device", channelsCount)
            
            
            //fvar channelAddress = AudioObjectPropertyAddress(mSelector: UInt32(kAudioObjectPropertyElementName), mScope: <#AudioObjectPropertyScope#>, mElement: <#AudioObjectPropertyElement#>)
            
            for channel in 0...channelsCount {
                // NSLog("Getting volume for channel \(channel).")
                
                // now, build a PropertyAddress that describes the input gain control on it
                var inputVolumeControlAddress = AudioObjectPropertyAddress(mSelector: UInt32(kAudioDevicePropertyVolumeScalar), mScope: UInt32(kAudioDevicePropertyScopeInput), mElement: UInt32(0));
                
                var currentVolume: Float32 = 0;
                var volumeSize = UInt32(sizeof(Float32));
                
                error = AudioObjectGetPropertyData(inputDevice, &inputVolumeControlAddress, 0, nil, &volumeSize, &currentVolume);
                if(error != 0) {
                    NSLog("Core Audio reports error when trying to retrieve the current volume: \(osStatusToString(error))");
                    return;
                }
                
                // NSLog("WOO, got current volume for channel \(channel): %f", currentVolume);
            }
            
            // Now, to see if the gain is settable on it:
        });
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}
