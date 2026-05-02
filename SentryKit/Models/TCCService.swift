// TCCService.swift
// SentryKit
//
// TCC Service definitions and metadata

import Foundation

/// Represents a macOS TCC (Transparency, Consent, and Control) service category.
enum TCCService: String, CaseIterable, Identifiable, Codable, Comparable {
    // MARK: - Core Privacy Services
    case screenCapture          = "kTCCServiceScreenCapture"
    case accessibility          = "kTCCServiceAccessibility"
    case fullDiskAccess         = "kTCCServiceSystemPolicyAllFiles"
    case inputMonitoring        = "kTCCServiceListenEvent"
    case microphone             = "kTCCServiceMicrophone"
    case camera                 = "kTCCServiceCamera"

    // MARK: - Data Access Services
    case photos                 = "kTCCServicePhotos"
    case contacts               = "kTCCServiceAddressBook"
    case calendar               = "kTCCServiceCalendar"
    case reminders              = "kTCCServiceReminders"
    case speechRecognition      = "kTCCServiceSpeechRecognition"
    case mediaLibrary           = "kTCCServiceMediaLibrary"
    case bluetooth              = "kTCCServiceBluetoothAlways"

    // MARK: - File & Folder Services
    case desktopFolder          = "kTCCServiceSystemPolicyDesktopFolder"
    case documentsFolder        = "kTCCServiceSystemPolicyDocumentsFolder"
    case downloadsFolder        = "kTCCServiceSystemPolicyDownloadsFolder"
    case networkVolumes         = "kTCCServiceSystemPolicyNetworkVolumes"
    case removableVolumes       = "kTCCServiceSystemPolicyRemovableVolumes"

    // MARK: - Automation & Developer
    case appleEvents            = "kTCCServiceAppleEvents"
    case developerTool          = "kTCCServiceDeveloperTool"
    case postEvent              = "kTCCServicePostEvent"

    // MARK: - Advanced / Security
    case endpointSecurity       = "kTCCServiceEndpointSecurityClient"
    case fileProviderPresence   = "kTCCServiceFileProviderPresence"
    case fileProviderDomain     = "kTCCServiceFileProviderDomain"
    case focusStatus            = "kTCCServiceFocusStatus"
    case location               = "kTCCServiceLocation"

    var id: String { rawValue }

    // MARK: - Display Properties

    /// Human-readable display name for the service.
    var displayName: String {
        switch self {
        case .screenCapture:        return "Screen Recording"
        case .accessibility:        return "Accessibility"
        case .fullDiskAccess:       return "Full Disk Access"
        case .inputMonitoring:      return "Input Monitoring"
        case .microphone:           return "Microphone"
        case .camera:               return "Camera"
        case .photos:               return "Photos"
        case .contacts:             return "Contacts"
        case .calendar:             return "Calendar"
        case .reminders:            return "Reminders"
        case .speechRecognition:    return "Speech Recognition"
        case .mediaLibrary:         return "Media & Apple Music"
        case .bluetooth:            return "Bluetooth"
        case .desktopFolder:        return "Desktop Folder"
        case .documentsFolder:      return "Documents Folder"
        case .downloadsFolder:      return "Downloads Folder"
        case .networkVolumes:       return "Network Volumes"
        case .removableVolumes:     return "Removable Volumes"
        case .appleEvents:          return "Automation"
        case .developerTool:        return "Developer Tools"
        case .postEvent:            return "Post Events"
        case .endpointSecurity:     return "Endpoint Security"
        case .fileProviderPresence: return "File Provider Presence"
        case .fileProviderDomain:   return "File Provider Domain"
        case .focusStatus:          return "Focus Status"
        case .location:             return "Location Services"
        }
    }

    /// SF Symbol name for the service icon.
    var symbolName: String {
        switch self {
        case .screenCapture:        return "rectangle.inset.filled.and.person.filled"
        case .accessibility:        return "accessibility"
        case .fullDiskAccess:       return "internaldrive"
        case .inputMonitoring:      return "keyboard"
        case .microphone:           return "mic.fill"
        case .camera:               return "camera.fill"
        case .photos:               return "photo.on.rectangle"
        case .contacts:             return "person.crop.circle"
        case .calendar:             return "calendar"
        case .reminders:            return "checklist"
        case .speechRecognition:    return "waveform"
        case .mediaLibrary:         return "music.note"
        case .bluetooth:            return "wave.3.right"
        case .desktopFolder:        return "menubar.dock.rectangle"
        case .documentsFolder:      return "doc.fill"
        case .downloadsFolder:      return "arrow.down.circle.fill"
        case .networkVolumes:       return "network"
        case .removableVolumes:     return "externaldrive"
        case .appleEvents:          return "applescript"
        case .developerTool:        return "hammer"
        case .postEvent:            return "cursorarrow.click"
        case .endpointSecurity:     return "shield.lefthalf.filled"
        case .fileProviderPresence: return "icloud.and.arrow.down"
        case .fileProviderDomain:   return "icloud"
        case .focusStatus:          return "moon.fill"
        case .location:             return "location.fill"
        }
    }

    /// Category grouping for the sidebar/dashboard.
    var category: ServiceCategory {
        switch self {
        case .screenCapture, .accessibility, .fullDiskAccess, .inputMonitoring:
            return .core
        case .microphone, .camera:
            return .hardware
        case .photos, .contacts, .calendar, .reminders, .speechRecognition, .mediaLibrary, .bluetooth:
            return .data
        case .desktopFolder, .documentsFolder, .downloadsFolder, .networkVolumes, .removableVolumes:
            return .filesAndFolders
        case .appleEvents, .developerTool, .postEvent:
            return .automation
        case .endpointSecurity, .fileProviderPresence, .fileProviderDomain, .focusStatus, .location:
            return .advanced
        }
    }

    /// tccutil service name (without the kTCCService prefix).
    var tccutilServiceName: String {
        switch self {
        case .screenCapture:        return "ScreenCapture"
        case .accessibility:        return "Accessibility"
        case .fullDiskAccess:       return "SystemPolicyAllFiles"
        case .inputMonitoring:      return "ListenEvent"
        case .microphone:           return "Microphone"
        case .camera:               return "Camera"
        case .photos:               return "Photos"
        case .contacts:             return "AddressBook"
        case .calendar:             return "Calendar"
        case .reminders:            return "Reminders"
        case .speechRecognition:    return "SpeechRecognition"
        case .mediaLibrary:         return "MediaLibrary"
        case .bluetooth:            return "BluetoothAlways"
        case .desktopFolder:        return "SystemPolicyDesktopFolder"
        case .documentsFolder:      return "SystemPolicyDocumentsFolder"
        case .downloadsFolder:      return "SystemPolicyDownloadsFolder"
        case .networkVolumes:       return "SystemPolicyNetworkVolumes"
        case .removableVolumes:     return "SystemPolicyRemovableVolumes"
        case .appleEvents:          return "AppleEvents"
        case .developerTool:        return "DeveloperTool"
        case .postEvent:            return "PostEvent"
        case .endpointSecurity:     return "EndpointSecurityClient"
        case .fileProviderPresence: return "FileProviderPresence"
        case .fileProviderDomain:   return "FileProviderDomain"
        case .focusStatus:          return "FocusStatus"
        case .location:             return "Location"
        }
    }

    /// System Settings URL scheme anchor for deep-linking.
    var settingsURLAnchor: String? {
        switch self {
        case .screenCapture:        return "Privacy_ScreenCapture"
        case .accessibility:        return "Privacy_Accessibility"
        case .fullDiskAccess:       return "Privacy_AllFiles"
        case .inputMonitoring:      return "Privacy_ListenEvent"
        case .microphone:           return "Privacy_Microphone"
        case .camera:               return "Privacy_Camera"
        case .photos:               return "Privacy_Photos"
        case .contacts:             return "Privacy_Contacts"
        case .calendar:             return "Privacy_Calendars"
        case .reminders:            return "Privacy_Reminders"
        case .speechRecognition:    return "Privacy_SpeechRecognition"
        case .mediaLibrary:         return "Privacy_MediaLibrary"
        case .bluetooth:            return "Privacy_Bluetooth"
        case .desktopFolder:        return "Privacy_DesktopFolder"
        case .documentsFolder:      return "Privacy_DocumentsFolder"
        case .downloadsFolder:      return "Privacy_DownloadsFolder"
        case .networkVolumes:       return "Privacy_NetworkVolume"
        case .removableVolumes:     return "Privacy_RemovableVolume"
        case .appleEvents:          return "Privacy_Automation"
        case .developerTool:        return "Privacy_DevTools"
        case .location:             return "Privacy_LocationServices"
        default:                    return nil
        }
    }

    /// Plain-English description of what this permission does.
    var explanation: String {
        switch self {
        case .screenCapture:
            return "Allows apps to capture the contents of your screen. Used by screenshot tools, screen recorders, and some window managers."
        case .accessibility:
            return "Allows apps to control your computer through accessibility features. Used by automation tools, mouse/keyboard enhancers, and window managers."
        case .fullDiskAccess:
            return "Allows apps to access all files on your disk, including protected system areas. Used by backup tools, cleaners, and security software."
        case .inputMonitoring:
            return "Allows apps to monitor keyboard and other input devices. Used by macro tools, productivity apps, and some security software."
        case .microphone:
            return "Allows apps to access your microphone for audio recording. Used by video conferencing, voice recording, and dictation apps."
        case .camera:
            return "Allows apps to access your camera for video capture. Used by video conferencing, photo, and scanning apps."
        case .photos:
            return "Allows apps to access your Photos library. Used by photo editors, social media, and backup apps."
        case .contacts:
            return "Allows apps to access your Contacts. Used by email clients, messaging apps, and CRM tools."
        case .calendar:
            return "Allows apps to read and modify your Calendar events. Used by scheduling, productivity, and meeting apps."
        case .reminders:
            return "Allows apps to access your Reminders. Used by task managers and productivity apps."
        case .speechRecognition:
            return "Allows apps to use speech recognition to convert audio to text. Used by dictation and voice control apps."
        case .mediaLibrary:
            return "Allows apps to access your Apple Music and media library. Used by music players and DJ software."
        case .bluetooth:
            return "Allows apps to use Bluetooth to communicate with nearby devices. Used by fitness trackers, audio devices, and IoT apps."
        case .desktopFolder:
            return "Allows apps to access files in your Desktop folder."
        case .documentsFolder:
            return "Allows apps to access files in your Documents folder."
        case .downloadsFolder:
            return "Allows apps to access files in your Downloads folder."
        case .networkVolumes:
            return "Allows apps to access files on network-attached storage and shared drives."
        case .removableVolumes:
            return "Allows apps to access files on external drives, USB sticks, and SD cards."
        case .appleEvents:
            return "Allows apps to control other apps using Apple Events / AppleScript automation. Used by workflow automation tools."
        case .developerTool:
            return "Allows apps to run software locally that does not meet the system's security policy. Used by developer tools and debuggers."
        case .postEvent:
            return "Allows apps to send simulated keyboard and mouse events. Used by automation and remote control apps."
        case .endpointSecurity:
            return "Allows apps to monitor system events for security purposes. Used by antivirus and endpoint protection software."
        case .fileProviderPresence:
            return "Allows file provider extensions to know when the user is browsing their files."
        case .fileProviderDomain:
            return "Allows apps to register as file providers in Finder."
        case .focusStatus:
            return "Allows apps to check whether you have Focus/Do Not Disturb enabled."
        case .location:
            return "Allows apps to determine your geographic location."
        }
    }

    /// Risk level indicator for the permission.
    var riskLevel: RiskLevel {
        switch self {
        case .fullDiskAccess, .endpointSecurity, .accessibility:
            return .high
        case .screenCapture, .inputMonitoring, .microphone, .camera, .appleEvents, .postEvent:
            return .medium
        default:
            return .low
        }
    }

    // MARK: - Comparable

    static func < (lhs: TCCService, rhs: TCCService) -> Bool {
        lhs.displayName < rhs.displayName
    }
}

// MARK: - Supporting Types

enum ServiceCategory: String, CaseIterable, Identifiable, Codable {
    case core           = "Core Privacy"
    case hardware       = "Hardware"
    case data           = "Data Access"
    case filesAndFolders = "Files & Folders"
    case automation     = "Automation"
    case advanced       = "Advanced"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .core:           return "lock.shield"
        case .hardware:       return "desktopcomputer"
        case .data:           return "cylinder.split.1x2"
        case .filesAndFolders: return "folder"
        case .automation:     return "gearshape.2"
        case .advanced:       return "wrench.and.screwdriver"
        }
    }

    var services: [TCCService] {
        TCCService.allCases.filter { $0.category == self }
    }
}

enum RiskLevel: String, Codable, Comparable {
    case low    = "Low"
    case medium = "Medium"
    case high   = "High"

    var color: String {
        switch self {
        case .low:    return "green"
        case .medium: return "orange"
        case .high:   return "red"
        }
    }

    private var sortOrder: Int {
        switch self {
        case .low:    return 0
        case .medium: return 1
        case .high:   return 2
        }
    }

    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
