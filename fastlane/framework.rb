class Framework
    attr_accessor :name, :dependencies, :relations
    
    def self.all 
        all_folders = [
            "WireNetwork",
            "WireAnalytics",
            "WireAuthentication",
            "WireBackup",
            "WireData",
            "WireDomain",
            "WireFoundation",
            "WireMessaging",
            "WireCalling",
            "WireLogging",
            "WireUI",
            "wire-ios",
            "wire-ios-canvas",
            "wire-ios-data-model",
            "wire-ios-images",
            "wire-ios-link-preview",
            "wire-ios-mocktransport",
            "wire-ios-request-strategy",
            "wire-ios-share-engine",
            "wire-ios-sync-engine",
            "wire-ios-system",
            "wire-ios-testing",
            "wire-ios-transport",
            "wire-ios-utilities",
            "wire-ios-ziphy",
        ]

        frameworks = all_folders.reduce({}) do |hash, framework| 
            hash["#{framework}"] ||= Framework.new(framework) 
            hash
        end

        frameworks["wire-ios"].add_dependency(frameworks["wire-ios-share-engine"])
        frameworks["wire-ios"].add_dependency(frameworks["wire-ios-sync-engine"])
        frameworks["wire-ios"].add_dependency(frameworks["WireBackup"])
        frameworks["wire-ios"].add_dependency(frameworks["WireFoundation"])
        frameworks["wire-ios"].add_dependency(frameworks["WireAuthentication"])
        frameworks["wire-ios"].add_dependency(frameworks["WireData"])
        frameworks["wire-ios"].add_dependency(frameworks["WireMessaging"])
        frameworks["wire-ios"].add_dependency(frameworks["WireCalling"])
        frameworks["wire-ios"].add_dependency(frameworks["wire-ios-testing"]) # included in WireiOSTests
        frameworks["wire-ios"].add_dependency(frameworks["WireLogging"])


        frameworks["wire-ios-sync-engine"].add_dependency(frameworks["wire-ios-request-strategy"])
        frameworks["wire-ios-sync-engine"].add_dependency(frameworks["WireNetwork"])
        frameworks["wire-ios-sync-engine"].add_dependency(frameworks["WireAnalytics"])
        frameworks["wire-ios-sync-engine"].add_dependency(frameworks["WireDomain"])
        frameworks["wire-ios-sync-engine"].add_dependency(frameworks["wire-ios-testing"]) # included in WireSyncEngineiOSTests
        frameworks["wire-ios-sync-engine"].add_dependency(frameworks["WireLogging"])
        
        frameworks["wire-ios-share-engine"].add_dependency(frameworks["WireLogging"])

        frameworks["wire-ios-request-strategy"].add_dependency(frameworks["wire-ios-data-model"])
        frameworks["wire-ios-request-strategy"].add_dependency(frameworks["WireNetwork"])
        frameworks["wire-ios-request-strategy"].add_dependency(frameworks["WireLogging"])
        
        frameworks["wire-ios-data-model"].add_dependency(frameworks["wire-ios-images"])
        frameworks["wire-ios-data-model"].add_dependency(frameworks["wire-ios-link-preview"])
        frameworks["wire-ios-data-model"].add_dependency(frameworks["wire-ios-transport"])
        frameworks["wire-ios-data-model"].add_dependency(frameworks["WireFoundation"])
        frameworks["wire-ios-data-model"].add_dependency(frameworks["WireData"])
        frameworks["wire-ios-data-model"].add_dependency(frameworks["wire-ios-testing"]) # included in WireDataModelTests
        frameworks["wire-ios-data-model"].add_dependency(frameworks["WireLogging"])
        
        frameworks["wire-ios-mocktransport"].add_dependency(frameworks["wire-ios-testing"])


        frameworks["wire-ios-transport"].add_dependency(frameworks["wire-ios-utilities"])
        frameworks["wire-ios-transport"].add_dependency(frameworks["wire-ios-testing"]) # included in WireTransportTests
        frameworks["wire-ios-transport"].add_dependency(frameworks["WireLogging"])
        
        frameworks["wire-ios-link-preview"].add_dependency(frameworks["wire-ios-utilities"])
        frameworks["wire-ios-link-preview"].add_dependency(frameworks["WireFoundation"])
        
        frameworks["wire-ios-images"].add_dependency(frameworks["wire-ios-utilities"])

        frameworks["wire-ios-utilities"].add_dependency(frameworks["wire-ios-system"])
        frameworks["wire-ios-utilities"].add_dependency(frameworks["WireFoundation"])
        frameworks["wire-ios-utilities"].add_dependency(frameworks["WireLogging"])
        
        frameworks["wire-ios-testing"].add_dependency(frameworks["wire-ios-system"])

        frameworks["WireDomain"].add_dependency(frameworks["wire-ios-transport"])
        frameworks["WireDomain"].add_dependency(frameworks["wire-ios-data-model"])
        frameworks["WireDomain"].add_dependency(frameworks["WireNetwork"])
        frameworks["WireDomain"].add_dependency(frameworks["WireFoundation"])
        frameworks["WireDomain"].add_dependency(frameworks["WireLogging"])
        
        frameworks["WireNetwork"].add_dependency(frameworks["WireFoundation"])
        frameworks["WireNetwork"].add_dependency(frameworks["WireLogging"])
        
        frameworks["WireAuthentication"].add_dependency(frameworks["WireDomain"])
        frameworks["WireAuthentication"].add_dependency(frameworks["WireFoundation"])
        frameworks["WireAuthentication"].add_dependency(frameworks["WireUI"])
        frameworks["WireAuthentication"].add_dependency(frameworks["WireLogging"])
        
        frameworks["WireBackup"].add_dependency(frameworks["WireFoundation"])
        frameworks["WireBackup"].add_dependency(frameworks["WireLogging"])
        
        frameworks["WireMessaging"].add_dependency(frameworks["WireFoundation"])
        frameworks["WireMessaging"].add_dependency(frameworks["WireLogging"])

        frameworks["WireCalling"].add_dependency(frameworks["WireFoundation"])
        frameworks["WireCalling"].add_dependency(frameworks["WireLogging"])

        frameworks["WireUI"].add_dependency(frameworks["WireLogging"])
        frameworks["WireUI"].add_dependency(frameworks["WireFoundation"])
        frameworks["WireUI"].add_dependency(frameworks["WireDomain"])
        
        frameworks["WireAnalytics"].add_dependency(frameworks["WireLogging"])
        
        frameworks
    end

    def initialize(name)
      @name = name
      @dependencies = []
      @relations = []
    end
  
    def add_dependency(dependency)
      @dependencies << dependency
      dependency.relations << self
    end

    def schemes
        result = [scheme]
        result << relations.map { |framework| framework.schemes }
        result.flatten
    end
    
    def scheme
        to_scheme(name)
    end

    private

    def to_scheme(name)
        case name
        when "wire-ios"
            "Wire-iOS"
        when "WireFoundation"
            "WireFoundationAll" # use a custom scheme that includes all targets of WireFoundation, fastlane does not found WireUI-Package
        when "WireUI"
            "WireUIAll" # use a custom scheme that includes all targets of WireUI, fastlane does not found WireUI-Package
        when "WireNetwork"
            "WireNetworkAll" # if a package has multiple targets, fastlane does not found <Package>-Package
        when "WireAuthentication"
            "WireAuthenticationAll"
        when "wire-ios-ziphy"
            "Ziphy"
        when "WireBackup"
            "WireBackupAll"
        when "WireData"
            "WireDataAll"
        when "WireMessaging"
            "WireMessagingAll" # use a custom scheme that includes all targets in the package
        when "WireCalling"
            "WireCallingAll" # use a custom scheme that includes all targets in the package
        when "WireDomain"
            name
        when "WireAnalytics"
            "WireAnalyticsAll" # if a package has multiple targets, fastlane does not found <Package>-Package
        when "WireLogging"
            "WireLoggingAll" # if a package has multiple targets, fastlane does not find <Package>-Package
        when "wire-ios-mocktransport"
            "WireMockTransport"
        else
            name.gsub('ios-', '').split('-').map.with_index { |part, index| part.capitalize }.join
        end
    end
end
