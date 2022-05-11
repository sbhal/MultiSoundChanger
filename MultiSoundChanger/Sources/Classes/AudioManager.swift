//
//  AudioManager.swift
//  MultiSoundChanger
//
//  Created by Dmitry Medyuho on 15.11.2020.
//  Copyright © 2020 Dmitry Medyuho. All rights reserved.
//

import AudioToolbox
import Foundation

// MARK: - Protocols

protocol AudioManager: class {
    func getDefaultOutputDevice() -> AudioDeviceID
    func getOutputDevices() -> [AudioDeviceID: String]?
    func selectDevice(deviceID: AudioDeviceID)
    func getSelectedDeviceVolume() -> Float?
    func setSelectedDeviceVolume(masterChannelLevel: Float, leftChannelLevel: Float, rightChannelLevel: Float)
    func isSelectedDeviceMuted() -> Bool
    func toggleMute()
    
    var isMuted: Bool { get }
}

// MARK: - Implementation

final class AudioManagerImpl: AudioManager {
    private let audio: Audio = AudioImpl()
    private let devices: [AudioDeviceID: String]?
    private var selectedDevice: AudioDeviceID?
    
    init() {
        devices = audio.getOutputDevices()
        printDevices()
    }
    
    func getDefaultOutputDevice() -> AudioDeviceID {
        return audio.getDefaultOutputDevice()
    }
    
    func getOutputDevices() -> [AudioDeviceID: String]? {
        return devices
    }
    
    func isAggregateDevice(deviceID: AudioDeviceID) -> Bool {
        return audio.isAggregateDevice(deviceID: deviceID)
    }
    
    func selectDevice(deviceID: AudioDeviceID) {
        selectedDevice = deviceID
        audio.setOutputDevice(newDeviceID: deviceID)
        Logger.debug(Constants.InnerMessages.selectDevice(deviceID: String(deviceID)))
    }
    
    func getSelectedDeviceVolume() -> Float? {
        guard let selectedDevice = selectedDevice else {
            return nil
        }
        
        if audio.isAggregateDevice(deviceID: selectedDevice) {
            let aggregatedDevices = audio.getAggregateDeviceSubDeviceList(deviceID: selectedDevice)
            
            for device in aggregatedDevices {
                if audio.isOutputDevice(deviceID: device) {
                    return audio.getDeviceVolume(deviceID: device).max()
                }
            }
        } else {
            return audio.getDeviceVolume(deviceID: selectedDevice).max()
        }
        
        return nil
    }
    
    func setSelectedDeviceVolume(masterChannelLevel: Float, leftChannelLevel: Float, rightChannelLevel: Float) {
        guard let selectedDevice = selectedDevice else {
            return
        }
        
        let isMute = masterChannelLevel < Constants.muteVolumeLowerbound
            && leftChannelLevel < Constants.muteVolumeLowerbound
            && rightChannelLevel < Constants.muteVolumeLowerbound
        
        if audio.isAggregateDevice(deviceID: selectedDevice) {
            var aggregatedDevices = audio.getAggregateDeviceSubDeviceList(deviceID: selectedDevice)
            
            var aggregatedDevicesNamesDict: [String: AudioDeviceID] = [:]
            if(audio.getDeviceName(deviceID: selectedDevice) == "nc700+"){
                for device in aggregatedDevices {
                    aggregatedDevicesNamesDict[audio.getDeviceName(deviceID: device)] = device
                }
                if aggregatedDevicesNamesDict["bose_nc_700"] != nil {
//                    Logger.error("Aggregate device nc700+ contains bose_nc_700")
                    aggregatedDevices = [aggregatedDevicesNamesDict["bose_nc_700"] ?? 0] // ?? 0 is providing default value in case value is nil
                    audio.setDeviceMute(deviceID: aggregatedDevicesNamesDict["MacBook Pro Speakers"] ?? 0, isMute: true)
                } else {
//                    Logger.error("Aggregate device nc700+ does not contains bose_nc_700")
                    aggregatedDevices = [aggregatedDevicesNamesDict["MacBook Pro Speakers"] ?? 0]
                }
            }
            
            for device in aggregatedDevices {
                audio.setDeviceVolume(
                    deviceID: device,
                    masterChannelLevel: masterChannelLevel,
                    leftChannelLevel: leftChannelLevel,
                    rightChannelLevel: rightChannelLevel
                )
                audio.setDeviceMute(deviceID: device, isMute: isMute)
            }
        } else {
            audio.setDeviceVolume(
                deviceID: selectedDevice,
                masterChannelLevel: masterChannelLevel,
                leftChannelLevel: leftChannelLevel,
                rightChannelLevel: rightChannelLevel
            )
            audio.setDeviceMute(deviceID: selectedDevice, isMute: isMute)
        }
    }
    
    func setSelectedDeviceMute(isMute: Bool) {
        guard let selectedDevice = selectedDevice else {
            return
        }
        
        if audio.isAggregateDevice(deviceID: selectedDevice) {
            let aggregatedDevices = audio.getAggregateDeviceSubDeviceList(deviceID: selectedDevice)
            
            for device in aggregatedDevices {
                audio.setDeviceMute(deviceID: device, isMute: isMute)
            }
        } else {
            audio.setDeviceMute(deviceID: selectedDevice, isMute: isMute)
        }
    }
    
    func isSelectedDeviceMuted() -> Bool {
        guard let selectedDevice = selectedDevice else {
            return false
        }
        
        if audio.isAggregateDevice(deviceID: selectedDevice) {
            let aggregatedDevices = audio.getAggregateDeviceSubDeviceList(deviceID: selectedDevice)
            
            guard let device = aggregatedDevices.first else {
                return false
            }
            
            return audio.isDeviceMuted(deviceID: device)
        } else {
            return audio.isDeviceMuted(deviceID: selectedDevice)
        }
    }
    
    func toggleMute() {
        if isSelectedDeviceMuted() {
            setSelectedDeviceMute(isMute: false)
            let volume = getSelectedDeviceVolume() ?? 0
            setSelectedDeviceVolume(masterChannelLevel: volume, leftChannelLevel: volume, rightChannelLevel: volume)
        } else {
            setSelectedDeviceMute(isMute: true)
        }
    }
    
    var isMuted: Bool {
        return isSelectedDeviceMuted()
    }
    
    private func printDevices() {
        guard let devices = devices else {
            return
        }
        Logger.debug(Constants.InnerMessages.outputDevices)
        for device in devices {
            Logger.debug(Constants.InnerMessages.debugDevice(deviceID: String(device.key), deviceName: device.value))
        }
    }
}
