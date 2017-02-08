// 
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
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "ZMBaseManagedObjectTest.h"


@interface PersonNameTests : ZMBaseManagedObjectTest
@property (nonatomic) NSLinguisticTagger *tagger;
@end

@implementation PersonNameTests

- (void)setUp
{
    [super setUp];
    self.tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:@[NSLinguisticTagSchemeScript] options:0];
}

- (void)tearDown
{
    [super tearDown];
    self.tagger = nil;
}



- (void)testThatNameIsSeparatedIntoComponents
{
    //given
    
    NSString *nameWithSpace = @"  Henry The Great Emporer";
    NSString *nameWithLineBreak = @"The Name \n Break Name";
    
    // when
    PersonName *nameWithSpaceComp = [PersonName personWithName:nameWithSpace];
    PersonName *nameWithLineBreakComp = [PersonName personWithName:nameWithLineBreak];
    
    //then
    NSArray *nameWithSpaceArray = @[@"Henry", @"The", @"Great", @"Emporer"];
    NSArray *nameWithLineBreakArray = @[@"The", @"Name", @"Break", @"Name"];
    
    XCTAssertEqualObjects(nameWithSpaceComp.components, nameWithSpaceArray);
    XCTAssertEqualObjects(nameWithLineBreakComp.components, nameWithLineBreakArray);

}

- (void)testThatItTrimsSpecialCharacters
{
    // given
    NSString *name1 = @"Henry (The) Great Emporer";
    NSString *name2 = @"The *Starred* Name";
    
    // when
    PersonName *nameComp1 = [PersonName personWithName:name1];
    PersonName *nameComp2 = [PersonName personWithName:name2];
    
    // then
    NSArray *nameArray1 = @[@"Henry", @"The", @"Great", @"Emporer"];
    NSArray *nameArray2 = @[@"The", @"Starred", @"Name"];
    
    XCTAssertEqualObjects(nameComp1.components, nameArray1);
    XCTAssertEqualObjects(nameComp2.components, nameArray2);
}

- (void)testThatItRemovesEmptyComponentFromComponents
{
    // given
    NSString *name1 = @"Henry () Great Emporer";
    NSString *name2 = @"The (   ) Empty Name";
    
    // when
    PersonName *nameComp1 = [PersonName personWithName:name1];
    PersonName *nameComp2 = [PersonName personWithName:name2];
    
    // then
    NSArray *nameArray1 = @[@"Henry", @"Great", @"Emporer"];
    NSArray *nameArray2 = @[@"The", @"Empty", @"Name"];
    
    XCTAssertEqualObjects(nameComp1.components, nameArray1);
    XCTAssertEqualObjects(nameComp2.components, nameArray2);
}

- (void)testThatItReturnsFirstComponentAsFirstName
{
    NSString *name1 = @"Henry The Great Emporer";
    
    PersonName *nameComp1 = [PersonName personWithName:name1];
    
    XCTAssertEqualObjects(nameComp1.givenName, @"Henry");

}

- (void)testThatItReturnsUntrimmedStringFullName
{
    // given
    NSString *name1 = @"Henry The Great Emporer";
    NSString *name2 = @"Henry ()";
    
    // when
    PersonName *nameComp1 = [PersonName personWithName:name1];
    PersonName *nameComp2 = [PersonName personWithName:name2];


    // then
    XCTAssertEqualObjects(nameComp1.fullName, name1);
    XCTAssertEqualObjects(nameComp2.fullName, name2);
}


- (void)testThatItReturnsFullNameWhenStringIsEmptyAfterTrimming
{
    // given
    NSString *name1 = @"(        )";
    NSString *name2 = @"**********";
    
    // when
    PersonName *nameComp1 = [PersonName personWithName:name1];
    PersonName *nameComp2 = [PersonName personWithName:name2];
    
    
    // then
    XCTAssertEqualObjects(nameComp1.fullName, name1);
    XCTAssertEqualObjects(nameComp2.fullName, name2);
}

# pragma mark - Composed Character Related Tests

- (void)testThatItReturnsFirstCharacterOfFirstAndLastNameAsInitials
{
    // given
    NSString *name1 = @"\u00cbmil Super Man";
    
    // when
    PersonName *personName1 = [PersonName personWithName:name1];

    // then
    XCTAssertEqualObjects(personName1.initials, @"\u00cbM");
}

- (void)testThatItReturnsOneCharacterWhenThereIsOnlyOneNameComponent
{
    // given
    NSString *name2 = @"E\u0308mil";
    
    // when
    PersonName *personName2 = [PersonName personWithName:name2];
    
    // then
    XCTAssertEqualObjects(personName2.initials, @"\u00cb");
}


# pragma mark - Language Related Tests

# pragma mark - Chinese

// CHINESE NAMES http:en.wikipedia.org/wiki/Chinese_name
//
// majority - 3 syllables (chinese characters) (1 family name followed by 2 given name which are always used together)
// 14% - 2 syllable
// <0.2% -  4 or more syllables, mostly compound surnames
// there is no white space between family name and given name
//
// A boy called Wei (伟) and belonging to the Zhang (张) family is called "Zhang Wei" and not "Wei Zhang"
// formally addressed as "Mr. Zhang"
// informally as "Zhang Wei" – never as “Wei"
//
// Romanization
// standard way of romanizing = Hanyu Pinyin
// Adoption of European-style name (typically English)
// by reversing the Chinese order (e.g., "Wei Zhang")
// by choosing a new name entirely (e.g., "John Zhang”)
// by combining both English and Chinese names into a single hybrid: "John Zhang Wei".
//
// Shumeng’s comment: “As far as I know, chinese people don’t usually use their real names on the internet though”
// Maybe we should not split them at all when they are not romanized?


- (void)testThatLinguisticTraggerRecognizesTraditionalAndSimplifiedChinese
{
    // given
    NSString *name1 = @"张伟";                // zhāng wěi - simplified Han (script code: Hans)
    NSString *name2 = @"張偉";                // zhāng wěi - traditional Han (script code: Hant)
    
    // when
    self.tagger.string = name1;
    NSArray *tags1 = [self.tagger tagsInRange:NSMakeRange(0, self.tagger.string.length) scheme:NSLinguisticTagSchemeScript options:0 tokenRanges:nil];
    
    self.tagger.string = name2;
    NSArray *tags2 = [self.tagger tagsInRange:NSMakeRange(0, self.tagger.string.length) scheme:NSLinguisticTagSchemeScript options:0 tokenRanges:nil];
    
    // then
    XCTAssertEqualObjects(tags1.firstObject, @"Hani");
    XCTAssertEqualObjects(tags2.firstObject, @"Hani");
}

- (void)testThatChineseNamesAreSeparatedCorrectly
{
    // given
    NSString *name1 = @"李淑蒙";              // Lǐ Shūméng - Lǐ (李) is the secondName, Shūméng (淑蒙) the firstName

    // when
    PersonName *nameComp1 = [PersonName personWithName:name1];

    // then
    XCTAssertEqualObjects(nameComp1.givenName, @"李淑蒙");
}

- (void)testThatChineseNamesReturnFirstTwoCharactersAsInitials
{
    // given
    NSString *name1 = @"李淑蒙";
    
    // when
    PersonName *nameComp1 = [PersonName personWithName:name1];
    
    // then
    XCTAssertEqualObjects(nameComp1.initials, @"李淑");
}

- (void)testThatChineseNamesReturnOneCharactersIfTheNameConsistsOfOnlyOneCharacter
{
    // given
    NSString *name3 = @"李";
    
    // when
    PersonName *nameComp3 = [PersonName personWithName:name3];
    
    // then
    XCTAssertEqualObjects(nameComp3.initials, @"李");
}

# pragma mark - Japanese


//     JAPANESE NAMES http://en.wikipedia.org/wiki/Japanese_name
//
//     Usually 1 surname, 1 given name, 0 middle name
//
//     family name precedes the given name, separated by a space
//     surnames mostly comprised of one, two or three kanji characters
//     Use of a space in given names (to separate first and middle names) is not allowed
//
//     People with mixed Japanese and foreign parentage may have middle names
//
//     usually written in kanji (Chinese characters), some names use hiragana or even katakana, or a mixture of kanji and kana.
//     may include archaic versions of characters, very uncommon kanji, or even kanji which no longer exist in modern Japanese
//
//     formal reference: family name
//     informal situations and cases where the speaker is older than, superior to, or very familiar with the named individual: given name
//
//     Forming abbreviations by concatenating the first two morae of two names common for celebrities


/// XXX: Disabled this test because it does not work on iOS 8.3
- (void)DISABLED_testThatLinguisticTraggerRecognizesJapanese
{
    // given
    NSString *name1 = @"ツルネン マルテイ";         // katakana for Tsurunen Marutei
    NSString *name2 = @"有道 出人";                // kanji for Arudou Debito
    NSString *name3 = @"ひら がな";                // hiragana
    
    // when
    self.tagger.string = name1;
    NSArray *tags1 = [self.tagger tagsInRange:NSMakeRange(0, self.tagger.string.length) scheme:NSLinguisticTagSchemeScript options:0 tokenRanges:nil];
    
    self.tagger.string = name2;
    NSArray *tags2 = [self.tagger tagsInRange:NSMakeRange(0, self.tagger.string.length) scheme:NSLinguisticTagSchemeScript options:0 tokenRanges:nil];
    
    self.tagger.string = name3;
    NSArray *tags3 = [self.tagger tagsInRange:NSMakeRange(0, self.tagger.string.length) scheme:NSLinguisticTagSchemeScript options:0 tokenRanges:nil];
    
    // then
    XCTAssertEqualObjects(tags1.firstObject, @"Jpan");
    XCTAssertEqualObjects(tags2.firstObject, @"Hani"); // problematic since this is also chinese, the only difference is that japanese family and given names are separated by white space
    XCTAssertEqualObjects(tags3.firstObject, @"Hani"); // problematic since this is also chinese, the only difference is that japanese family and given names are separated by white space
}

- (void)testThatSecondComponentIsGivenNameInJapanesNames
{
    // given
    NSString *name1 = @"ツルネン マルテイ";         // katakana for Tsurunen Marutei
    NSString *name2 = @"有道 出人";                // kanji for Arudou Debito
    NSString *name3 = @"ひら がな";                // hiragana
    
    // when
    PersonName *nameComp1 = [PersonName personWithName:name1];
    PersonName *nameComp2 = [PersonName personWithName:name2];
    PersonName *nameComp3 = [PersonName personWithName:name3];
    
    // then
    XCTAssertEqualObjects(nameComp1.givenName, @"マルテイ");
    XCTAssertEqualObjects(nameComp2.givenName, @"出人");
    XCTAssertEqualObjects(nameComp3.givenName, @"がな");
}

- (void)testThatItReturnsFirstTwoCharactersForInitialsOfJapanesNames
{
    // given
    NSString *name1 = @"ツルネン マルテイ";         // katakana for Tsurunen Marutei
    NSString *name2 = @"有道 出人";                // kanji for Arudou Debito
    NSString *name3 = @"ひ";                // hiragana
    
    // when
    PersonName *nameComp1 = [PersonName personWithName:name1];
    PersonName *nameComp2 = [PersonName personWithName:name2];
    PersonName *nameComp3 = [PersonName personWithName:name3];
    
    // then
    XCTAssertEqualObjects(nameComp1.initials, @"ツル");
    XCTAssertEqualObjects(nameComp2.initials, @"有道");
    XCTAssertEqualObjects(nameComp3.initials, @"ひ");
}

# pragma mark - Hindi / Devanagari

- (void)testThatLinguisticTraggerRecognizesSanskrit
{
    // given
    NSString *name1 = @"मोहनदास करमचंद गांधी";    // Mohandas Karamchand Gandhi - Davanagari (script code: Deva), most commonly used script for writing Sanskrit (e.g. in Hindi, Nepali, Marathi, Konkani, Bodo and Maithili)
    NSString *name2 = @"મોહનદાસ કરમચંદ ગાંધી";     // Mohandas Karamchand Gandhi - Gujarati (script code: Gujr)
    
    // when
    self.tagger.string = name1;
    NSArray *tags1 = [self.tagger tagsInRange:NSMakeRange(0, self.tagger.string.length) scheme:NSLinguisticTagSchemeScript options:0 tokenRanges:nil];
    
    self.tagger.string = name2;
    NSArray *tags2 = [self.tagger tagsInRange:NSMakeRange(0, self.tagger.string.length) scheme:NSLinguisticTagSchemeScript options:0 tokenRanges:nil];
    
    // then
    XCTAssertEqualObjects(tags1.firstObject, @"Deva");
    XCTAssertEqualObjects(tags2.firstObject, @"Gujr");
}

- (void)testThatHindiNamesAreSeparatedCorrectly
{
    // given
    NSString *name1 = @"मोहनदास करमचंद गांधी"; // Mohandas Karamchand Gandhi - Mohandas Karamchand is the secondName, Gandhi the firstName
    
    // when
    PersonName *nameComp1 = [PersonName personWithName:name1];
    
    // then
    XCTAssertEqualObjects(nameComp1.givenName, @"गांधी");
    XCTAssertEqualObjects(nameComp1.fullName, @"मोहनदास करमचंद गांधी");
}


# pragma mark - Arabic

//     ARABIC NAMES http:en.wikipedia.org/wiki/Arabic_name
//     General structure: <given name> ibn <father’ s name> ibn <grandfather’s names> <family name>
//     “ibn" = “son of”
//     “bint” = “daughter of”
//     “ibn" and “bint" are dropped in most Arab countries today
//
//     Some Arab countries use only two- and three-word names, and sometimes four-word names in official or legal matters.
//     first name = personal name
//     middle name = father's name
//     last name = family name.
//
//     Muhammad ibn Saeed ibn Abd al-Aziz al-Filasteeni
//     (Muhammad, son of Saeed, son of Abd al-Aziz, the Palestinian)
//        محمد بن سعيد بن عبد العزيز الفلسطيني
//     muḥammad ibn saʻīdi ibn ʻabdi l-ʻazīzi l-filasṭīnī
//     Given Name: Muhammad
//     Called Name: Muhammad OR Abu Kareem (Father of Kareem)
//     Last Name: al-Filasteeni
//
//     Westernisation
//     Almost all Arabic-speaking countries (excluding for example Saudi Arabia or Bahrain) have now adopted a westernised way of naming.
//     no single accepted Arabic transliteration
//     —> Abdul Rahman, Abdoul Rahman, Abdur Rahman, Abdurahman, Abd al-Rahman, or Abd ar-Rahman
//
//     Common Mistakes
//     Abdul Rahman bin Omar al-Ahmad
//     "Abdul” means "servant of the" and is not by itself a name
//     "Abdul" / "Abd" is always followed by one of the 99 names of God (http://en.wikipedia.org/wiki/Names_of_God_in_Islam), the feminine equivalent is "Amat" / "Amah"
//     given name: “Abdul Rahman”
//     family name: Ahmad
//
//     Sami Ben Ahmed
//     "bin" (also written as Ben) and "ibn" indicate the family chain
//     given name: Sami
//     family name: Ben Ahmed


- (void)testThatLinguisticTraggerRecognizesArabic
{
    // given
    NSString *name1 = @"محمد بن سعيد بن عبد العزيز الفلسطيني";    // Muhammad ibn Saeed ibn Abd al-Aziz al-Filasteeni - Arabic (script code: Arab)
    
    // when
    self.tagger.string = name1;
    NSArray *tags1 = [self.tagger tagsInRange:NSMakeRange(0, self.tagger.string.length) scheme:NSLinguisticTagSchemeScript options:0 tokenRanges:nil];
    
    // then
    XCTAssertEqualObjects(tags1.firstObject, @"Arab");
}


- (void)testThatArabicNamesAreSeparatedCorrectly
{
    // given
    
    NSString *name1 = @"محمد بن سعيد بن عبد العزيز الفلسطيني"; // Muhammad ibn Saeed ibn Abd al-Aziz al-Filasteeni, where "محمد" (Muhammad) is the firstName, but "comes last" as it"s written from right to left
    NSString *name2 = @"عبد الله الثاني بن الحسين";          // Abd Allāh aṯ-ṯānī bin al-Ḥusain, where "عبد الله" (Abdullah II / Abd Allāh aṯ-ṯānī) is the firstName
    NSString *name3 = @"امه العليم السوسوه‎";               // Amat Al'Alim Alsoswa, where "امه العليم" (Amat al Alim = Slave of the all knowing) is the firstName
    
    // when
    PersonName *nameComp1 = [PersonName personWithName:name1];
    PersonName *nameComp2 = [PersonName personWithName:name2];
    PersonName *nameComp3 = [PersonName personWithName:name3];

    // then
    XCTAssertEqualObjects(nameComp1.givenName, @"محمد");
    XCTAssertEqualObjects(nameComp1.fullName, name1);
    
    XCTAssertEqualObjects(nameComp2.givenName, @"عبد الله");
    XCTAssertEqualObjects(nameComp2.fullName, name2);
    
    XCTAssertEqualObjects(nameComp3.givenName, @"امه العليم");
    XCTAssertEqualObjects(nameComp3.fullName, name3);
}

- (void)testThatItReturnsFirstLettersOFFirstAndLastComponentForArabicInitials
{
    // given
    
    NSString *name1 = @"محمد بن سعيد بن عبد العزيز الفلسطيني"; // Muhammad ibn Saeed ibn Abd al-Aziz al-Filasteeni, where "محمد" (Muhammad) is the firstName, but "comes last" as it"s written from right to left
    NSString *name2 = @"عبد الله الثاني بن الحسين";          // Abd Allāh aṯ-ṯānī bin al-Ḥusain, where "عبد الله" (Abdullah II / Abd Allāh aṯ-ṯānī) is the firstName
    NSString *name3 = @"امه العليم السوسوه‎";               // Amat Al'Alim Alsoswa, where "امه العليم" (Amat al Alim = Slave of the all knowing) is the firstName
    
    // when
    PersonName *nameComp1 = [PersonName personWithName:name1];
    PersonName *nameComp2 = [PersonName personWithName:name2];
    PersonName *nameComp3 = [PersonName personWithName:name3];
    
    // then
    XCTAssertEqualObjects(nameComp1.initials, @"ما");
    XCTAssertEqualObjects(nameComp2.initials, @"عا");
    XCTAssertEqualObjects(nameComp3.initials, @"اا");
}

# pragma mark - Mixed Language Sets

- (void)DISABLE_testThatMixedNamesReturnFirstComponentAsFirstName
{
    // This fails on CI only, for some obscure reasons
    // given
    NSString *name2 = @"李淑蒙 (shumeng)";    // Lǐ Shūméng - Lǐ (李) is the secondName, Shūméng (淑蒙) the firstName
    NSString *name3 = @"shumeng (李淑蒙)";    // should use the chinese name as "firstName"
    
    // when
    PersonName *nameComp2 = [PersonName personWithName:name2];
    PersonName *nameComp3 = [PersonName personWithName:name3];
    
    // then
    XCTAssertEqualObjects(nameComp2.givenName, @"李淑蒙");
    XCTAssertEqualObjects(nameComp3.givenName, @"shumeng");
}

- (void)DISABLE_testThatMixedNamesReturnFirstLettersOfFirstAndLastComponent
{
    // This fails on CI only, for some obscure reasons
    // given
    NSString *name1 = @"李淑蒙 (shumeng)";
    NSString *name2 = @"shumeng (李淑蒙)";
    
    // when
    PersonName *nameComp1 = [PersonName personWithName:name1];
    PersonName *nameComp2 = [PersonName personWithName:name2];
    
    // then
    XCTAssertEqualObjects(nameComp1.initials, @"李s");
    XCTAssertEqualObjects(nameComp2.initials, @"s李");
    
}

- (void)testItGetsTheFullCharacterForComposedCharactersThatSpanMoreThanOneStringIndexPoint;
{
    NSString *name1 = @"𠀲𫝶𫝷𫝚𫞉𫟘善屠屮 𠂎";
    NSString *name2 = @"( 𝓐𝓑 𝓑";

    PersonName *nameComp1 = [PersonName personWithName:name1];
    PersonName *nameComp2 = [PersonName personWithName:name2];

    XCTAssertNotEqual(nameComp1.components.count, 0u);
    XCTAssertNotEqual(nameComp2.components.count, 0u);

    NSString *first1 = [nameComp1.components[0] zmFirstComposedCharacter];
    NSString *second1 = [nameComp1.components[0] zmSecondComposedCharacter];
    XCTAssertEqualObjects(first1, @"𠀲");
    XCTAssertEqualObjects(second1, @"𫝶");
    
    NSString *first2 = [nameComp2.components[0] zmFirstComposedCharacter];
    NSString *second2 = [nameComp2.components[0] zmSecondComposedCharacter];
    XCTAssertEqualObjects(first2, @"𝓐");
    XCTAssertEqualObjects(second2, @"𝓑");
//
//    NSRange r0 = [foo rangeOfComposedCharacterSequenceAtIndex:0];
//    NSRange r1 = [foo rangeOfComposedCharacterSequenceAtIndex:NSMaxRange(r0)];
//    NSLog(@"%@", NSStringFromRange(r0));
//    NSLog(@"%@", NSStringFromRange(r1));
}

- (void)testThatTheSecondComposedCharacterReturnsNilWhenTheStringIsShorterThan2;
{
    XCTAssertNil([@"" zmSecondComposedCharacter]);
    XCTAssertNil([@"A" zmSecondComposedCharacter]);
    XCTAssertNil([@"𝓐" zmSecondComposedCharacter]);
}

- (void)testThatTheFirstComposedCharacterReturnsNilWhenTheStringIsEmpty;
{
    XCTAssertNil([@"" zmFirstComposedCharacter]);
}


- (void)testThatTheInitialsAreGeneratedCorrectlyIfThereIsOnlyOneCompositeCharacter
{
    // C.f. https://wearezeta.atlassian.net/browse/MEC-656
    
    XCTAssertEqualObjects([PersonName personWithName:@""].initials, @"");
    XCTAssertEqualObjects([PersonName personWithName:@"A"].initials, @"A");
    XCTAssertEqualObjects([PersonName personWithName:@"𝓐"].initials, @"𝓐");
}

@end
