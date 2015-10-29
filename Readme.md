# Decode-XCodeGhostBeacon

This software is a PowerShell [1] script which decodes the encrypted message the XCodeGhost malware [2] attempts to send to its command & control servers.

## Usage
1. Export the beacon payload data in binary form into a file. This can be done with Wireshark or other network analysis tools.
2. Source Decode-XCodeGhostBeacon.ps1 into your PowerShell session or script:
```PowerShell
PS C:\> .\Decrypt-XCodeGhostBeacon.ps1
```
3. Execute the cmdlet on your exported beacon payload data.
```PowerShell
PS C:\> Get-Content C:\payload.bin -Encoding Byte | Decrypt-XCodeGhostBeacon.ps1
```

## Technical Description
Decode-XCodeGhost decrypts the malware payload by using the DES algorithm [3] in ECB mode with PKCS#7 padding using a key of "stringWithFormat". 

This reveals the details of the infected iOS device and the name of the infected app. This information can be used to positively identify the infected iOS device, and then supplied to the user or IT helpdesk staff to positively identify the infected app(s) to remove from that device.

Prior to the invention of Decode-XCodeGhostBeacon there were two main problems with the detection and elimination of the malware.

First, detection systems typically can only detect the IP address of an infected device. Researchers have determined the destinations the malware sends its encrypted data to, so systems can reliably detect the malware by watching for communications to those specific destinations. When that communication is detected the IP address of the source (i.e. the infected device) is found. However, the devices are mobile and IP addresses are recycled when a device stops being used on a network. So, unless the owner can be found before the device leaves the network and the IP Address is recycled, detection relies on having a flawless audit history mapping historic IP address usage to an actual user’s name.

Second, detection systems cannot determine which app(s) on an infected device actually have the malware. This makes remediation difficult since the only instruction which can be given to the user is to find a listing of infected iOS apps published online [4] and remove any of their apps which are on the list. However, those lists are not exhaustive and are being updated daily as more infected apps are found.  This requires painstaking research to determine which apps are infected (if it is at all possible) or lengthy trial-and-error removing apps until the infection goes away.

Figure 1:
```
000001480065000ABF21BBB454A4682D583C59F14332C76655EBF7902C28A220C2C7F12AB2DA10FD1B79D89A3D28813FF3259DC6BD5145A4BC75F3F5D464E873F2DEC04568F87CB591D34BDF47130F29BDC2D4E7A3B32A6AD9CF758D10B5A5F4637E9B47DC9CF762EF108E3B2F92D86F61EC0380D0AD2B918FA76825BBEA0EDF7282D9140B5249C2534C7783C11C9055D5028D943A50BF70DCEE0C6F13A44DAF8FE14B6793B7DE0A55E7AA52677B763090C5F020BFACCD10087F17231D04FCCDFDAB5D0B3A1A804CB848C39D1ADAC4AA883B8CEA6B359931C203CB2D51EC67AAB9E320E207F30B9E893FF377878E426D02FEDA1885B68D087DE70176BBADC498804B7BA27D903E50998531D4548FF1FCF0B62AF56FFF9222EC1597116E3426A9C45AD38FB17DEB1BA41A76D0B4FF11B86B1726C65B3101D44C6DD210B3E66BC2B368CDCCA4B0233C
```

Figure 2:
```json
{
  "country" : "US",
  "os" : "9.0.2",
  "type" : "iPhone5,1",
  "app" : "下厨房",
  "name" : "John Smith’s iPhone",
  "idfv" : "0A570606-CEE6-45B0-8A39-14BA0113D4F9",
  "timestamp" : "1444160481",
  "bundle" : "com.xiachufang.recipe",
  "status" : "resignActive",
  "version" : "4.3.2",
  "language" : "en-US"
}
```

Decrypt-XCodeGhostBeacon solves both problems. Figure 1 depicts the encrypted bytes (shown as hexadecimal since many of them cannot be printed in this format). No worthwhile information about the infected device or app can be ascertained. Figure 2 shows the decrypted message. It contains useful information for identifying the device and owner:
* The iOS device’s model: iPhone 5
* The version of iOS it has: 9.0.2
* The name the user has given their iOS device: John Smith’s iPhone.
It also contains information about the infected app:
•	The app’s name "下厨房", which translates as "The Kitchen" [5]
* The app’s bundle name "com.xiachufang.recipe". This can be used to positively identify the app in cases where the app’s name is not in English.
* The app’s version "4.3.2". Many app makers have released new versions of their apps to remove XCodeGhost. If the owner of the device wants to try updating their app, this version number can be used to tell which versions should not be trusted.
 
Decrypt-XCodeGhost can be used manually or built-in to other software. Its manual usage is described here, but building it into other software is straightforward for one familiar with Powershell.

First, a capture of the traffic is required. This can be collected by a network monitoring system or locally by a tool such as tcpdump or wireshark.

An analyst must locate the beacon message. This is an HTTP POST packet containing form data marked as "application/x-www-form-urlencoded". [6]. The analyst then extracts the HTTP POST form data and saves it into a file. Usage of Decrypt-XCodeGhostBeacon is then straightforward, as shown in Figure 3.
 
## Additional Information
This invention builds upon work of other security researchers, notably Xavier Mertens [6]. Mertens focused on device owners identifying their own compromised devices and app developers identifying their compromised apps.

A security practitioner familiar with packet capturing and inspection will discover that the HTTP POST sent by the malware includes some identifying detail in clear text which may help identify the infected app. The HTTP Referrer header may hint at the infected app, but this text may not always contain useful information.

In one case, the name of the app was apparent (See figure 4). In another, the app’s name was written in Chinese and could not be written in an HTTP Header. Instead, it went through a process called URL encoding to produce the string "%E4%B8%8B%E5%8E%A8%E6%88%BF". URL decoding this string results in the Chinese characters "下厨房" which must be translated into English. In English, the phrase means "The Kitchen". A search of the iOS app store for "the Kitchen" reveals many results. [7]
 
A more straight-forward way to determine the actual infected app would be to obtain the app’s bundle identifier as Decode-XCodeGhostBeacon does. The app’s bundle identifier must be globally unique to each app and contain only alphanumeric symbols, dashes, and periods [8]. Entering the app’s bundle identifier into a Google Search is often enough to definitively identify the infected app.

The decryption algorithm, DES, is a standard. Decrypt-XCodeGhostBeacon uses Windows’ built-in DES decryption routine which can be implemented by a developer familiar with development in .NET or Powershell. The key used to decrypt the payload was found included in the XCodeGhost source code posted online. [9]

Between development of this tool and uploading the code to GitHub, James Condon posted a similar solution for decrypting XCodeGhost beacons in python.[19]

## Background Information
XCodeGhost is malware infecting several iOS apps (apps for iPhones or iPads). It was discovered in September 2015 by iOS developers [10] and further elaborated by the security firm Palo Alto Networks [2] [11] [12] [4] [13]. The malware was distributed in a copy of the developer tools which are used to create apps for iOS devices. Because the developer tools take a long time to download, many Chinese developers downloaded a local copy from a Chinese website to speed up their download. This copy of XCode included the virus.

When the app developer compiled their app it would include the XCodeGhost virus. This strategy is different than many other mobile malware strategies which rely on Trojan or falsely advertised apps. XCodeGhost was bundled with legitimate apps created by well-known developers. [11]

Once discovered, an individual claiming to be the author published the source code of the malware to github, a source code collaboration website. [9]. Researchers have verified that the source code does match the XCodeGhost malware seen in the wild, so this source code is likely to be legitimate. [6]

While researching the malware it was discovered that the communication it sends to its servers is an encrypted message containing details about the infected iOS device and app. [9]

The source code for XCodeGhost includes the method by which the malware encrypts the payload. It uses DES [3] in ECB mode [14], using the PKCS#7 padding [15] method, and always uses the key of "stringWithFormat". The source code uses a variable name referencing AES [16], but attempts to use the AES algorithm to decrypt the payload fail; the name may be a mistake or diversion by the writer of XCodeGhost.

## References
- [1] 	Wikipedia, "Windows Powershell," [Online]. Available: https://en.wikipedia.org/wiki/Windows_PowerShell. [Accessed 19 October 2015].
- [2] 	C. Xiao, "Novel Malware XcodeGhost Modifies Xcode, Infects Apple iOS Apps and Hits App Store," 17 September 2015. [Online]. Available: http://researchcenter.paloaltonetworks.com/2015/09/novel-malware-xcodeghost-modifies-xcode-infects-apple-ios-apps-and-hits-app-store/.
- [3] 	Wikipedia, "Data Encryption Standard," [Online]. Available: https://en.wikipedia.org/wiki/Data_Encryption_Standard. [Accessed 19 October 2015].
- [4] 	D. Goodin, "Apple scrambles after 40 malicious "XcodeGhost" apps haunt App Store," 21 September 2015. [Online]. Available: http://arstechnica.com/security/2015/09/apple-scrambles-after-40-malicious-xcodeghost-apps-haunt-app-store/.
- [5] 	Google Translate, "Google Translate," [Online]. Available: https://translate.google.com/#zh-CN/en/%E4%B8%8B%E5%8E%A8%E6%88%BF. [Accessed 19 October 2015].
- [6] 	X. Mertens, "Detecting XCodeGhost Activity," 21 September 2015. [Online]. Available: https://isc.sans.edu/diary/Detecting+XCodeGhost+Activity/20171.
- [7] 	Fnd, "fnd search for "the Kitchen"," fnd, [Online]. Available: https://fnd.io/#/us/search?mediaType=ios&term=the%20kitchen. [Accessed 19 October 2015].
- [8] 	Apple Inc., "Configuring Your Xcode Project for Distribution," [Online]. Available: https://developer.apple.com/library/ios/documentation/IDEs/Conceptual/AppDistributionGuide/ConfiguringYourApp/ConfiguringYourApp.html. [Accessed 19 October 2015].
- [9] 	XCodeGhost, "XcodeGhostSource / XCodeGhost," 18 September 2015. [Online]. Available: https://github.com/XcodeGhostSource/XcodeGhost.
- [10] 	JoeyBlue_, "Post on weibo," 17 September 2015. [Online]. Available: http://weibo.com/1650375593/CAV5fqdo3?from=page_1005051650375593_profile&wvr=6&mod=weibotime&type=comment.
- [11] 	C. Xiao, "Malware XcodeGhost Infects 39 iOS Apps, Including WeChat, Affecting Hundreds of Millions of Users," 18 September 2015. [Online]. Available: http://researchcenter.paloaltonetworks.com/2015/09/malware-xcodeghost-infects-39-ios-apps-including-wechat-affecting-hundreds-of-millions-of-users/.
- [12] 	C. Xiao, "Update: XcodeGhost Attacker Can Phish Passwords and Open URLs through Infected Apps," 18 September 2015. [Online]. Available: http://researchcenter.paloaltonetworks.com/2015/09/update-xcodeghost-attacker-can-phish-passwords-and-open-urls-though-infected-apps/.
- [13] 	G. Keizer, "XcodeGhost used unprecedented infection strategy against Apple," 26 September 2015. [Online]. Available: http://www.computerworld.com/article/2986768/application-development/xcodeghost-used-unprecedented-infection-strategy-against-apple.html.
- [14] 	Wikipedia, "Block cipher mode of operation," [Online]. Available: https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation#Electronic_Codebook_.28ECB.29. [Accessed 19 October 2015].
- [15] 	R. Housley, "Cryptographic Message Syntax (CMS)," September 2009. [Online]. Available: http://tools.ietf.org/html/rfc5652#section-6.3.
- [16] 	Wikipedia, "Advanced Encryption Standard," [Online]. Available: https://en.wikipedia.org/wiki/Advanced_Encryption_Standard. [Accessed 19 October 2015].
- [17] 	Tcpdump, [Online]. Available: http://www.tcpdump.org/.
- [18] 	Wireshark, [Online]. Available: https://www.wireshark.org/.
- [19]  J. Condon, "Retrospection & Full PCAP Reveal Instances of XcodeGhost Dating Back to April 2015" [Online]. Available: https://www.protectwise.com/blog/retrospection-and-full-pcap-reveal-instances-of-xcodeghost-dating-back-to-april-2015/. [Accessed 29 October 2015]


