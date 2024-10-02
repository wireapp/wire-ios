class Framework
    attr_accessor :name, :dependencies, :relations
    
    def self.all 
        all_folders = [
            "wire-ios",
            "wire-ios-canvas",
            "wire-ios-cryptobox",
            "wire-ios-data-model",
            "wire-ios-images",
            "wire-ios-link-preview",
            "wire-ios-mocktransport",
            "wire-ios-notification-engine",
            "wire-ios-protos",
            "wire-ios-request-strategy",
            "wire-ios-share-engine",
            "wire-ios-sync-engine",
            "wire-ios-system",
            "wire-ios-testing",
            "wire-ios-transport",
            "wire-ios-utilities",
            "wire-ios-ziphy",
            "WireAPI",
            "WireAnalytics",
            "WireDomain",
            "WireUI",
            "WireFoundation",
        ]

        frameworks = all_folders.reduce({}) do |hash, framework| 
            hash["#{framework}"] ||= Framework.new(framework) 
            hash
        end

        frameworks["wire-ios"].add_dependency(frameworks["wire-ios-notification-engine"])
        frameworks["wire-ios"].add_dependency(frameworks["wire-ios-share-engine"])
        frameworks["wire-ios"].add_dependency(frameworks["wire-ios-sync-engine"])
        
        frameworks["wire-ios-notification-engine"].add_dependency(frameworks["wire-ios-request-strategy"])
        frameworks["wire-ios-sync-engine"].add_dependency(frameworks["wire-ios-request-strategy"])
        frameworks["wire-ios-sync-engine"].add_dependency(frameworks["WireAPI"])
        frameworks["wire-ios-sync-engine"].add_dependency(frameworks["WireDomain"])
        frameworks["wire-ios-share-engine"].add_dependency(frameworks["wire-ios-request-strategy"])

        frameworks["wire-ios-request-strategy"].add_dependency(frameworks["wire-ios-data-model"])
        frameworks["wire-ios-request-strategy"].add_dependency(frameworks["WireAPI"])
        
        frameworks["wire-ios-data-model"].add_dependency(frameworks["wire-ios-cryptobox"])
        frameworks["wire-ios-data-model"].add_dependency(frameworks["wire-ios-images"])
        frameworks["wire-ios-data-model"].add_dependency(frameworks["wire-ios-link-preview"])
        frameworks["wire-ios-data-model"].add_dependency(frameworks["wire-ios-protos"])
        frameworks["wire-ios-data-model"].add_dependency(frameworks["wire-ios-transport"])

        frameworks["wire-ios-mocktransport"].add_dependency(frameworks["wire-ios-testing"])
        frameworks["wire-ios-mocktransport"].add_dependency(frameworks["wire-ios-cryptobox"])
        frameworks["wire-ios-mocktransport"].add_dependency(frameworks["wire-ios-protos"])

        frameworks["wire-ios-cryptobox"].add_dependency(frameworks["wire-ios-utilities"])
        frameworks["wire-ios-transport"].add_dependency(frameworks["wire-ios-utilities"])
        frameworks["wire-ios-link-preview"].add_dependency(frameworks["wire-ios-utilities"])
        frameworks["wire-ios-images"].add_dependency(frameworks["wire-ios-utilities"])

        frameworks["wire-ios-utilities"].add_dependency(frameworks["wire-ios-system"])
        frameworks["wire-ios-testing"].add_dependency(frameworks["wire-ios-system"])
        
        frameworks["WireDomain"].add_dependency(frameworks["wire-ios-transport"])
        frameworks["WireDomain"].add_dependency(frameworks["wire-ios-data-model"])
        frameworks["WireDomain"].add_dependency(frameworks["WireAPI"])
        frameworks["WireDomain"].add_dependency(frameworks["WireFoundation"])

        frameworks["WireAPI"].add_dependency(frameworks["WireFoundation"])

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
        when "WireDomain"
            "WireDomain"
        when "WireAPI", "WireAnalytics", "WireUI", "WireFoundation"
            name
        when "wire-ios-mocktransport"
            "WireMockTransport"
        else
            name.gsub('ios-', '').split('-').map.with_index { |part, index| part.capitalize }.join
        end
    end
end
