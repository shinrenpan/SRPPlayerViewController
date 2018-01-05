[![LICENSE](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
[![Donate](https://img.shields.io/badge/Donate-PayPal-yellow.svg?style=flat-square)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=LC58N7VZUST5N)


A simply media play UIViewController base on [ijkplayer k0.7.4][1] without control panel.

[中文說明][3].


## Feature
- TV connected support.
- Media Format: please see [ijkplayer][4].
- URL Protocol: please see [ijkplayer][4].


## Compile
- Follow [ijkplayer-builder][2] to build (ijkplayer k0.7.4) **IJKMediaFramework.framework, libssl.a, libcrypto.a**, then drag them into ijkplayer folder. 

![](README/1.png)

- Run build.sh


## Usage
- Drag **IJKMediaFramework.framework, libssl.a, libcrypto.a, SRPPlayerViewController.framework** into your project.
- In your project add **libz.tbd** into `Linked Frameworks and Libraries`.
- Use SRPPlayerViewController or subclass, see [IPTV].

```objc
SRPPlayerViewController *mvc = [[SRPPlayerViewController alloc]init];
mvc.mediaURL = ...
```





[1]: https://github.com/Bilibili/ijkplayer/releases/tag/k0.7.4 "k0.7.4"
[2]: https://github.com/shinrenpan/ijkplayer-builder
[3]: README_TW.md
[4]: https://github.com/Bilibili/ijkplayer "ijkplayer"
[IPTV]: https://github.com/shinrenpan/IPTV
