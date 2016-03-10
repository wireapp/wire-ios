// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.


#import <Foundation/Foundation.h>


typedef uint64_t UIDRand;

/**
 A unique identifier for an event
 */
class EventUID {
    
public:
    
    /// the "empty" UID
    static const EventUID UID_NONE;
    
    EventUID() = default;
    EventUID(int seq, UIDRand rnd);
    
    /// the sequence number
    int sequence { -1 };
    
    /// the random part
	UIDRand random { 0 };
    
    /// whether the UID is invalid or not set
    bool empty() const;
    /// whether the UID is invalid or not set
    bool isNull() const;
    /// whether the UID valid
    bool isSet() const;
    
    /// comparison
    bool operator==(const EventUID& other) const;
    bool operator!=(const EventUID& other) const;
    bool operator<(const EventUID& other) const;
    bool operator>(const EventUID& other) const;
    bool operator<=(const EventUID& other) const;
    bool operator>=(const EventUID& other) const;
    
//    /// read from a JSON representation (hex)
//    void readFromJson(const ZJsonVal& jObj);
//    
//    /// read from a string (hex)
//    void fromString(const std::string& s);

    
    /// compare
    int compare(const EventUID& other) const;

    NSString *description() const;

    /// serialize for DB
//    std::string serialize() const;
    
    /// deserialize for DB
//    void deserialize(const std::string& blob);
};
