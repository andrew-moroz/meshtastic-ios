//
//  MasterDataProcessor.swift
//  Meshtastic
//
//  Created by Thomas Huttinger on 01.10.20.
//

import Foundation


class MasterDataProcessor
{
    //---------------------------------------------------------------------------------------
    // MARK: - private class variables
    //---------------------------------------------------------------------------------------

    private var nodeInfo_DP: NodeInfo_DP
    private var myNodeInfo_DP: MyNodeInfo_DP

    //---------------------------------------------------------------------------------------

        
    //---------------------------------------------------------------------------------------
    // MARK: - public class variables
    //---------------------------------------------------------------------------------------

    public var radio: RadioConfig_DO
    public var preferences: UserPreferences_DO
    public var channelSettings: ChannelSettings_DO
    public var myInfo: MyNodeInfo_DO

    //---------------------------------------------------------------------------------------

    
    // MARK: - Initialization
    init()
    {
        nodeInfo_DP = NodeInfo_DP()
        myNodeInfo_DP = MyNodeInfo_DP()

        radio = RadioConfig_DO()
        preferences = UserPreferences_DO()
        channelSettings = ChannelSettings_DO()
        myInfo = MyNodeInfo_DO()
    }
    
    
    //---------------------------------------------------------------------------------------
    // MARK: - private functions
    //---------------------------------------------------------------------------------------

    /// Writes the ChannelSettings_DO - dataobject into protobuf structure
    ///
    /// - Returns: a ChannelSetting protobuf structure
    ///
    private func channelSettings_write2ProtoBuf() -> ChannelSettings
    {
        var pbChannelSettings: ChannelSettings!
        pbChannelSettings = ChannelSettings()
        
        pbChannelSettings.bandwidth = self.radio.channelSettings.bandwidth
        pbChannelSettings.channelNum = self.radio.channelSettings.channelNum
        pbChannelSettings.codingRate = self.radio.channelSettings.codingRate
        pbChannelSettings.spreadFactor = self.radio.channelSettings.spreadFactor
        switch self.radio.channelSettings.modemConfig
        {
            case Enumerations.ModemConfig.bw125Cr45Sf128 :
                pbChannelSettings.modemConfig = ChannelSettings.ModemConfig.bw125Cr45Sf128
            case Enumerations.ModemConfig.bw500Cr45Sf128 :
                pbChannelSettings.modemConfig = ChannelSettings.ModemConfig.bw500Cr45Sf128
            case Enumerations.ModemConfig.bw3125Cr48Sf512 :
                pbChannelSettings.modemConfig = ChannelSettings.ModemConfig.bw3125Cr48Sf512
            case Enumerations.ModemConfig.bw125Cr48Sf4096 :
                pbChannelSettings.modemConfig = ChannelSettings.ModemConfig.bw125Cr48Sf4096
            case Enumerations.ModemConfig.UNRECOGNIZED(0) :
                pbChannelSettings.modemConfig = ChannelSettings.ModemConfig.UNRECOGNIZED(0)
            default:
                //pbChannelSettings.modemConfig = ChannelSettings.ModemConfig.bw125Cr48Sf4096
                break
        }
        pbChannelSettings.name = self.radio.channelSettings.name
        pbChannelSettings.psk = self.radio.channelSettings.psk
        pbChannelSettings.txPower = self.radio.channelSettings.txPower
        
        return pbChannelSettings
    }
    
    
    /// Writes the Preferences_DO - dataobject into protobuf structure
    ///
    /// - Returns: a UserPreferences protobuf structure
    ///
    private func preferences_write2ProtoBuf() -> RadioConfig.UserPreferences
    {
        var pbUserPreferences: RadioConfig.UserPreferences!
        pbUserPreferences = RadioConfig.UserPreferences()
        
        pbUserPreferences.ignoreIncoming = self.radio.preferences.ignoreIncoming
        pbUserPreferences.lsSecs = self.radio.preferences.lsSecs
        pbUserPreferences.meshSdsTimeoutSecs = self.radio.preferences.meshSdsTimeoutSecs
        pbUserPreferences.minWakeSecs = self.radio.preferences.minWakeSecs
//        pbUserPreferences.numMissedToFail = self.radio.preferences.numMissedToFail
        pbUserPreferences.phoneSdsTimeoutSec = self.radio.preferences.phoneSdsTimeoutSec
        pbUserPreferences.phoneTimeoutSecs = self.radio.preferences.phoneTimeoutSecs
        pbUserPreferences.positionBroadcastSecs = self.radio.preferences.positionBroadcastSecs
        pbUserPreferences.screenOnSecs = self.radio.preferences.screenOnSecs
        pbUserPreferences.sdsSecs = self.radio.preferences.sdsSecs
        pbUserPreferences.sendOwnerInterval = self.radio.preferences.sendOwnerInterval
        pbUserPreferences.waitBluetoothSecs = self.radio.preferences.waitBluetoothSecs
        pbUserPreferences.wifiApMode = self.radio.preferences.wifiApMode
        pbUserPreferences.wifiPassword = self.radio.preferences.wifiPassword
        pbUserPreferences.wifiSsid = self.radio.preferences.wifiSsid
        
        return pbUserPreferences
    }
    
    
    private func user_write2ProtoBuf(user_DO: User_DO) -> User
    {
        var user: User = User()
        user.id = user_DO.id
        user.shortName = user_DO.shortName
        user.longName = user_DO.longName
        user.macaddr = user_DO.macaddr
        
        return user
    }
    
    //---------------------------------------------------------------------------------------

    
    
    
    
    //---------------------------------------------------------------------------------------
    // MARK: - public functions
    //---------------------------------------------------------------------------------------
    
    public func resetDB()
    {
        // This is a temporary functioon called after BLE disconnect. Later when implementing a database
        // we need to highlight the users who are online on the connected device.
        DataBase.shared.nodeArray.removeAll()
    }

    /// Parse the decoded protoBuf structure "FromRadio" and write the data into our own data classes
    public func parseFromRadioPb(fromRadioDecoded: FromRadio) {
        var pbDataType: FromRadio.OneOf_PayloadVariant
        if (fromRadioDecoded.payloadVariant == nil) {
            return
        }
        pbDataType = fromRadioDecoded.payloadVariant!
        let nodeInfo = NodeInfo_DO()
        let user = User_DO()
        let position = Position_DO()
        
        if (pbDataType == FromRadio.OneOf_PayloadVariant.packet(fromRadioDecoded.packet))
        {
            print("######## MeshPacket ########")
            let meshPacket = fromRadioDecoded.packet
            let mpDataType = meshPacket.payloadVariant
            if (mpDataType == MeshPacket.OneOf_PayloadVariant.decoded(meshPacket.decoded))
            {
                print("######## MeshPacket.Decoded ########")
                let subPacket = meshPacket.decoded
                let sbDataType = subPacket.payload
                
                switch subPacket.portnum
                {
                    case PortNum.textMessageApp:
                        print("######## From TextMessageApp ########")
                        
                        let nodeInfo_DP = NodeInfo_DP()
                        let chatMessage = ChatMessage_DO()
                        let chatMessage_DP = ChatMessage_DP()
                        let nodeSender = nodeInfo_DP.dbRead(nodeId: meshPacket.from)
                        let nodeReceiver = nodeInfo_DP.dbRead(nodeId: meshPacket.to)
                        chatMessage.messageID = meshPacket.id
                        chatMessage.messageTimestamp = Date.currentTimeStamp
                        chatMessage.fromUserID = nodeSender?.user.id ?? ""
                        chatMessage.fromUserLongName = nodeSender?.user.longName ?? ""
                        if (meshPacket.to == DataBase.shared.broadcastNodeId)
                        {
                            chatMessage.toUserID = "BC"
                            chatMessage.toUserLongName = "broadcast"
                        }
                        else
                        {
                            chatMessage.toUserID = nodeReceiver?.user.id ?? ""
                            chatMessage.toUserLongName = nodeReceiver?.user.longName ?? ""
                        }
                        chatMessage.messagePayload = String(decoding: subPacket.payload, as: UTF8.self)
                        chatMessage_DP.dbWrite(chatMessage)
                        
                        MasterViewController.shared.chatMessageUpdated()
                        print(String(decoding: subPacket.payload, as: UTF8.self))

                    case PortNum.nodeinfoApp:
                        print("######## From NodeInfoApp ########")
                        var decodedInfo = User()
                        decodedInfo = try! User(serializedData: subPacket.payload)
                        user.id = decodedInfo.id
                        user.longName = decodedInfo.longName
                        user.shortName = decodedInfo.shortName
                        user.macaddr = decodedInfo.macaddr
                        
                        self.nodeInfo_DP.dbWrite(user, nodeId: meshPacket.from)
                        MasterViewController.shared.userUpdated(user: user)
                        MasterViewController.shared.DebugPrint2View(text: "*** decoded:\n" + decodedInfo.debugDescription)
                        print("user:")
                        print(decodedInfo)

                    case PortNum.positionApp:
                        print("######## From PositionApp ########")
                        var decodedPosition = Position()
                        decodedPosition = try! Position(serializedData: subPacket.payload)
                        position.latitudeI = decodedPosition.latitudeI
                        position.longitudeI = decodedPosition.longitudeI
                        position.altitude = decodedPosition.altitude
                        position.batteryLevel = decodedPosition.batteryLevel
                        position.time = decodedPosition.time
                        
                        self.nodeInfo_DP.dbWrite(position, nodeId: meshPacket.from)
                        MasterViewController.shared.DebugPrint2View(text: "*** decoded:\n" + decodedPosition.debugDescription)
                        print("position:")
                        print(decodedPosition)
                        
                    default:
                        break
                }
                
//                let sbAckType = subPacket.ack
//               if (sbDataType == DataMessage.OneOf_PayloadVariant.position(subPacket.position)) {
//                    print("######## MeshPacket.Decoded.SubPacket.Position ########")
//                    position.latitudeI = subPacket.position.latitudeI
//                    position.longitudeI = subPacket.position.longitudeI
//                    position.altitude = subPacket.position.altitude
//                    position.batteryLevel = subPacket.position.batteryLevel
//                    position.time = subPacket.position.time
//
//                    self.nodeInfo_DP.dbWrite(position, nodeId: meshPacket.from)
//                }
//                else if (sbDataType == DataMessage.OneOf_Payload.data(subPacket.data))
//                {
//                    print("######## MeshPacket.Decoded.SubPacket.DataMessage ########")
//                    switch subPacket.data.portnum
//                    {
//                        case PortNum.textMessageApp:
//                            print("######## From TextMessageApp ########")
//
//                            let nodeInfo_DP = NodeInfo_DP()
//                            let chatMessage = ChatMessage_DO()
//                            let chatMessage_DP = ChatMessage_DP()
//                            let nodeSender = nodeInfo_DP.dbRead(nodeId: meshPacket.from)
//                            let nodeReceiver = nodeInfo_DP.dbRead(nodeId: meshPacket.to)
//                            chatMessage.messageID = meshPacket.id
//                            chatMessage.messageTimestamp = Date.currentTimeStamp
//                            chatMessage.fromUserID = nodeSender?.user.id ?? ""
//                            chatMessage.fromUserLongName = nodeSender?.user.longName ?? ""
//                            if (meshPacket.to == DataBase.shared.broadcastNodeId)
//                            {
//                                chatMessage.toUserID = "BC"
//                                chatMessage.toUserLongName = "broadcast"
//                            }
//                            else
//                            {
//                                chatMessage.toUserID = nodeReceiver?.user.id ?? ""
//                                chatMessage.toUserLongName = nodeReceiver?.user.longName ?? ""
//                            }
//                            chatMessage.messagePayload = String(decoding: subPacket.data.payload, as: UTF8.self)
//                            chatMessage_DP.dbWrite(chatMessage)
//
//                            MasterViewController.shared.chatMessageUpdated()
//                            print(String(decoding: subPacket.data.payload, as: UTF8.self))
//
//                        case PortNum.nodeinfoApp:
//                            print("######## From NodeInfoApp ########")
//                            var decodedInfo = User()
//                            decodedInfo = try! User(serializedData: subPacket.data.payload)
//                            user.id = decodedInfo.id
//                            user.longName = decodedInfo.longName
//                            user.shortName = decodedInfo.shortName
//                            user.macaddr = decodedInfo.macaddr
//
//                            self.nodeInfo_DP.dbWrite(user, nodeId: meshPacket.from)
//                            MasterViewController.shared.userUpdated(user: user)
//                            MasterViewController.shared.DebugPrint2View(text: "*** decoded:\n" + decodedInfo.debugDescription)
//                            print("user:")
//                            print(decodedInfo)
//
//                        case PortNum.positionApp:
//                            print("######## From PositionApp ########")
//                            var decodedPosition = Position()
//                            decodedPosition = try! Position(serializedData: subPacket.data.payload)
//                            position.latitudeI = decodedPosition.latitudeI
//                            position.longitudeI = decodedPosition.longitudeI
//                            position.altitude = decodedPosition.altitude
//                            position.batteryLevel = decodedPosition.batteryLevel
//                            position.time = decodedPosition.time
//
//                            self.nodeInfo_DP.dbWrite(position, nodeId: meshPacket.from)
//                            MasterViewController.shared.DebugPrint2View(text: "*** decoded:\n" + decodedPosition.debugDescription)
//                            print("position:")
//                            print(decodedPosition)
//
//                        default:
//                            break
//                    }
//                }
//                else if (sbDataType == SubPacket.OneOf_Payload.user(subPacket.user))
//                {
//                    print("######## MeshPacket.Decoded.SubPacket.User ########")
//                    user.id = subPacket.user.id
//                    user.longName = subPacket.user.longName
//                    user.shortName = subPacket.user.shortName
//                    user.macaddr = subPacket.user.macaddr
//
//                    self.nodeInfo_DP.dbWrite(user, nodeId: meshPacket.from)
//                    MasterViewController.shared.userUpdated(user: user)
//
//                }
//                else if (sbAckType == SubPacket.OneOf_Ack.successID(subPacket.successID))
//                {
//                    print("######## MeshPacket.Decoded.SubPacket.Ack.Success ########")
//                    print(subPacket.successID)
//                }
//                else if (sbAckType == SubPacket.OneOf_Ack.failID(subPacket.failID))
//                {
//                    print("######## MeshPacket.Decoded.SubPacket.Ack.Fail ########")
//                    print(subPacket.failID)
//                }

                
                

            }
            else if (mpDataType == MeshPacket.OneOf_PayloadVariant.encrypted(meshPacket.encrypted))
            {
                print("######## MeshPacket.Encrypted ########")
                // We have nothing to do here
            }
        }
//        else if (pbDataType == FromRadio.OneOf_PayloadVariant.radio(fromRadioDecoded.radio) )
//        {
//            print("######## RadioConfig ########")
//            self.radio.hasPreferences = fromRadioDecoded.radio.hasPreferences
//            self.radio.hasChannelSettings = fromRadioDecoded.radio.hasChannelSettings
//            if (self.radio.hasPreferences)
//            {
//                self.preferences.positionBroadcastSecs = fromRadioDecoded.radio.preferences.positionBroadcastSecs
//                self.preferences.sendOwnerInterval = fromRadioDecoded.radio.preferences.sendOwnerInterval
//                self.preferences.numMissedToFail = fromRadioDecoded.radio.preferences.numMissedToFail
//                self.preferences.waitBluetoothSecs = fromRadioDecoded.radio.preferences.waitBluetoothSecs
//                self.preferences.screenOnSecs = fromRadioDecoded.radio.preferences.screenOnSecs
//                self.preferences.phoneTimeoutSecs = fromRadioDecoded.radio.preferences.phoneTimeoutSecs
//                self.preferences.phoneSdsTimeoutSec = fromRadioDecoded.radio.preferences.phoneSdsTimeoutSec
//                self.preferences.meshSdsTimeoutSecs = fromRadioDecoded.radio.preferences.meshSdsTimeoutSecs
//                self.preferences.sdsSecs = fromRadioDecoded.radio.preferences.sdsSecs
//                self.preferences.lsSecs = fromRadioDecoded.radio.preferences.lsSecs
//                self.preferences.minWakeSecs = fromRadioDecoded.radio.preferences.minWakeSecs
//                self.preferences.wifiSsid = fromRadioDecoded.radio.preferences.wifiSsid
//                self.preferences.wifiPassword = fromRadioDecoded.radio.preferences.wifiPassword
//                self.preferences.wifiApMode = fromRadioDecoded.radio.preferences.wifiApMode
//                self.preferences.ignoreIncoming = fromRadioDecoded.radio.preferences.ignoreIncoming
//                self.radio.preferences = self.preferences
//            }
//
//            if (self.radio.hasChannelSettings)
//            {
//                self.channelSettings.txPower = fromRadioDecoded.radio.channelSettings.txPower
//                switch fromRadioDecoded.radio.channelSettings.modemConfig
//                {
//                    case ChannelSettings.ModemConfig.bw125Cr45Sf128 :
//                        self.channelSettings.modemConfig = Enumerations.ModemConfig.bw125Cr45Sf128
//                    case ChannelSettings.ModemConfig.bw500Cr45Sf128 :
//                        self.channelSettings.modemConfig = Enumerations.ModemConfig.bw500Cr45Sf128
//                    case ChannelSettings.ModemConfig.bw3125Cr48Sf512 :
//                        self.channelSettings.modemConfig = Enumerations.ModemConfig.bw3125Cr48Sf512
//                    case ChannelSettings.ModemConfig.bw125Cr48Sf4096 :
//                        self.channelSettings.modemConfig = Enumerations.ModemConfig.bw125Cr48Sf4096
//                    case ChannelSettings.ModemConfig.UNRECOGNIZED(0):
//                        self.channelSettings.modemConfig = Enumerations.ModemConfig.UNRECOGNIZED(0)
//                    default:
//                        self.channelSettings.modemConfig = Enumerations.ModemConfig.bw125Cr48Sf4096
//                }
//                self.channelSettings.bandwidth = fromRadioDecoded.radio.channelSettings.bandwidth
//                self.channelSettings.spreadFactor = fromRadioDecoded.radio.channelSettings.spreadFactor
//                self.channelSettings.codingRate = fromRadioDecoded.radio.channelSettings.codingRate
//                self.channelSettings.channelNum = fromRadioDecoded.radio.channelSettings.channelNum
//                self.channelSettings.psk = fromRadioDecoded.radio.channelSettings.psk
//                self.channelSettings.name = fromRadioDecoded.radio.channelSettings.name
//
//                self.radio.channelSettings = self.channelSettings
//                MasterViewController.shared.updateFromDevice(radioConfig: self.radio)
//            }
//        }
        else if (pbDataType == FromRadio.OneOf_PayloadVariant.nodeInfo(fromRadioDecoded.nodeInfo) )
        {
            print("######## NodeInfo ########")
            nodeInfo.num = fromRadioDecoded.nodeInfo.num
            nodeInfo.hasUser = fromRadioDecoded.nodeInfo.hasUser
            nodeInfo.hasPosition = fromRadioDecoded.nodeInfo.hasPosition
            nodeInfo.snr = fromRadioDecoded.nodeInfo.snr
//            nodeInfo.nextHop = fromRadioDecoded.nodeInfo.nextHop
            if (nodeInfo.hasUser)
            {
                user.id = fromRadioDecoded.nodeInfo.user.id
                user.longName = fromRadioDecoded.nodeInfo.user.longName
                user.shortName = fromRadioDecoded.nodeInfo.user.shortName
                user.macaddr = fromRadioDecoded.nodeInfo.user.macaddr
                nodeInfo.user = user
            }
            
            if (nodeInfo.hasPosition)
            {
                position.latitudeI = fromRadioDecoded.nodeInfo.position.latitudeI
                position.longitudeI = fromRadioDecoded.nodeInfo.position.longitudeI
                position.altitude = fromRadioDecoded.nodeInfo.position.altitude
                position.batteryLevel = fromRadioDecoded.nodeInfo.position.batteryLevel
                position.time = fromRadioDecoded.nodeInfo.position.time
                nodeInfo.position = position
            }
            self.nodeInfo_DP.dbWrite(nodeInfo)
        }
        else if (pbDataType == FromRadio.OneOf_PayloadVariant.myInfo(fromRadioDecoded.myInfo) )
        {
            print("######## MyInfo ########")
            self.myInfo.myNodeNum = fromRadioDecoded.myInfo.myNodeNum
            self.myInfo.hasGps_p = fromRadioDecoded.myInfo.hasGps_p
//            self.myInfo.numChannels = fromRadioDecoded.myInfo.numChannels
            self.myInfo.region = fromRadioDecoded.myInfo.region
            self.myInfo.hwModel = fromRadioDecoded.myInfo.hwModelDeprecated
            self.myInfo.firmwareVersion = fromRadioDecoded.myInfo.firmwareVersion
            self.myInfo.errorCode = UInt32(fromRadioDecoded.myInfo.errorCode.rawValue)
            self.myInfo.errorAddress = fromRadioDecoded.myInfo.errorAddress
            self.myInfo.errorCount = fromRadioDecoded.myInfo.errorCount
//            self.myInfo.packetIDBits = fromRadioDecoded.myInfo.packetIDBits
//            self.myInfo.currentPacketID = fromRadioDecoded.myInfo.currentPacketID
            self.myInfo.nodeNumBits = fromRadioDecoded.myInfo.myNodeNum
            self.myInfo.messageTimeoutMsec = fromRadioDecoded.myInfo.messageTimeoutMsec
            self.myInfo.minAppVersion = fromRadioDecoded.myInfo.minAppVersion
            
            self.myNodeInfo_DP.dbWrite(self.myInfo)
        }
        else if (pbDataType == FromRadio.OneOf_PayloadVariant.configCompleteID(fromRadioDecoded.configCompleteID) )
        {
            print("######## ConfigCompleteID ########")
            print("calling MasterViewController.shared.tvcChats.Add_Update_Item()")
            MasterViewController.shared.tvcChats.Add_Update_Item()
        }
        else if (pbDataType == FromRadio.OneOf_PayloadVariant.rebooted(fromRadioDecoded.rebooted) )
        {
            print("######## Rebooted ########")
        }
    }
    
    
    /// Called by MasterViewController after the user has changed a radio-config value
    ///
    /// - Parameters:
    ///     - dataFieldName: The name of the datafield whose name was changed
    ///     - value: The new Value of the datafield
    ///
    public func radioConfig_setValue(dataFieldName: String, value: String, currentRadioConfig: RadioConfig_DO)
    {
        self.radio = currentRadioConfig
        
        switch dataFieldName
        {
            case "preferences.positionBroadcastSecs":
                self.radio.preferences.positionBroadcastSecs = UInt32(value) ?? 0
            case "preferences.sendOwnerInterval":
                self.radio.preferences.positionBroadcastSecs = UInt32(value) ?? 0
            case "preferences.numMissedToFail":
                self.radio.preferences.numMissedToFail = UInt32(value) ?? 0
            case "preferences.waitBluetoothSecs":
                self.radio.preferences.waitBluetoothSecs = UInt32(value) ?? 0
            case "preferences.screenOnSecs":
                self.radio.preferences.screenOnSecs = UInt32(value) ?? 0
            case "preferences.phoneTimeoutSecs":
                self.radio.preferences.phoneTimeoutSecs = UInt32(value) ?? 0
            case "preferences.phoneSdsTimeoutSec":
                self.radio.preferences.phoneSdsTimeoutSec = UInt32(value) ?? 0
            case "preferences.meshSdsTimeoutSecs":
                self.radio.preferences.meshSdsTimeoutSecs = UInt32(value) ?? 0
            case "preferences.sdsSecs":
                self.radio.preferences.sdsSecs = UInt32(value) ?? 0
            case "preferences.lsSecs":
                self.radio.preferences.lsSecs = UInt32(value) ?? 0
            case "preferences.minWakeSecs":
                self.radio.preferences.minWakeSecs = UInt32(value) ?? 0
            case "preferences.wifiSsid":
                self.radio.preferences.wifiSsid = value
            case "preferences.wifiPassword":
                self.radio.preferences.wifiPassword = value
            case "preferences.wifiApMode":
                self.radio.preferences.wifiApMode = Bool(value) ?? false
            case "preferences.ignoreIncoming":
                break
            case "channelSettings.txPower":
                self.radio.channelSettings.txPower = Int32(value) ?? 0
            case "channelSettings.modemConfig":
                switch value
                {
                    case "bw125Cr45Sf128":
                        self.radio.channelSettings.modemConfig = Enumerations.ModemConfig.bw125Cr45Sf128
                    case "bw500Cr45Sf128":
                        self.radio.channelSettings.modemConfig = Enumerations.ModemConfig.bw500Cr45Sf128
                    case "bw3125Cr48Sf512":
                        self.radio.channelSettings.modemConfig = Enumerations.ModemConfig.bw3125Cr48Sf512
                    case "bw125Cr48Sf4096":
                        self.radio.channelSettings.modemConfig = Enumerations.ModemConfig.bw125Cr48Sf4096
                    case "0":
                        self.radio.channelSettings.modemConfig = Enumerations.ModemConfig.UNRECOGNIZED(0)
                    default:
                        //self.radio.channelSettings.modemConfig = Enumerations.ModemConfig.bw125Cr45Sf128
                        break
                }
            case "channelSettings.bandwidth":
                self.radio.channelSettings.bandwidth = UInt32(value) ?? 0
            case "channelSettings.spreadFactor":
                self.radio.channelSettings.spreadFactor = UInt32(value) ?? 0
            case "channelSettings.codingRate":
                self.radio.channelSettings.codingRate = UInt32(value) ?? 0
            case "channelSettings.channelNum":
                self.radio.channelSettings.channelNum = UInt32(value) ?? 0
            case "channelSettings.psk":
                self.radio.channelSettings.psk = value.hexadecimal ?? Data("".utf8)
                //self.radio.channelSettings.psk = Data(value.utf8)
            case "channelSettings.name":
                self.radio.channelSettings.name = value
            default:
                break
        }

        let pbChannelSettings = channelSettings_write2ProtoBuf()
        let pbUserPreferences = preferences_write2ProtoBuf()
        
        BLEController.shared.writeRadioConfig(userPreferences: pbUserPreferences, channelSettings: pbChannelSettings)
        MasterViewController.shared.updateFromDevice(radioConfig: self.radio)
    }

    
    /// Called by MasterViewController after the user has changed the LoRa parameters
    ///
    /// - Parameters:
    ///     - bandwidth: LoRa bandwidth
    ///     - spreadingFactor: LoRa spreading factor
    ///     - codingRate: LoRa coding rate
    ///     - currentRadioConfig: the raidio config dataobject, containig the current (old) data
    ///
    public func radioConfig_setLoRaModulation(bandwidth: String, spreadingFactor: String, codingRate: String, currentRadioConfig: RadioConfig_DO)
    {
        self.radio = currentRadioConfig
        
        self.radio.channelSettings.bandwidth = UInt32(bandwidth) ?? 0
        self.radio.channelSettings.spreadFactor = UInt32(spreadingFactor) ?? 0
        self.radio.channelSettings.codingRate = UInt32(codingRate) ?? 0
        self.radio.channelSettings.modemConfig = Enumerations.ModemConfig.UNRECOGNIZED(0)

        let pbChannelSettings = channelSettings_write2ProtoBuf()
        let pbUserPreferences = preferences_write2ProtoBuf()

        BLEController.shared.writeRadioConfig(userPreferences: pbUserPreferences, channelSettings: pbChannelSettings)
        MasterViewController.shared.updateFromDevice(radioConfig: self.radio)
    }

    
    /// Called by MasterViewController after the user has changed the oner settings
    ///
    /// - Parameters:
    ///     - myUser_DO: The user data object, containing the updated data
    ///
    public func setOwner(myUser_DO: User_DO)
    {
        // Update database
        let myNode: NodeInfo_DO = nodeInfo_DP.getMyNodeObject()!
        let nodeInfo_DP: NodeInfo_DP = NodeInfo_DP()
        nodeInfo_DP.dbWrite(myUser_DO, nodeId: myNode.num)
        
        // Set to device
        let user = self.user_write2ProtoBuf(user_DO: myUser_DO)
        BLEController.shared.setOwner(myUser: user)
    }
    
    //---------------------------------------------------------------------------------------

    
    
    
    
}
