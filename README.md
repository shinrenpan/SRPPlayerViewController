[![LICENSE](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
[![Donate](https://img.shields.io/badge/Donate-PayPal-yellow.svg?style=flat-square)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=LC58N7VZUST5N)


A simply media play UIViewController base on [ijkplayer k0.7.4][1] without control panel.

[中文說明][3].

![](README/1.png)


# Feature
- TV connected support.
- Media Format: please see [ijkplayer][4].
- URL Protocol: please see [ijkplayer][4].


# Installation
Download the compiled [SRPPlayerViewController.framework][5] and [IJKMediaFramework.framework][6] (Both support i386, x86_64, armv7, arm64) and drag into your project.


# Usage
```objC
SRPPlayerViewController *mvc = [[SRPPlayerViewController alloc]init];
mvc.mediaURL = ...
```

or subclass SRPPlayerViewController.






[1]: https://github.com/Bilibili/ijkplayer/releases/tag/k0.7.4 "k0.7.4"
[3]: README_TW.md
[4]: https://github.com/Bilibili/ijkplayer "ijkplayer"
[5]: https://github.com/shinrenpan/SRPPlayerViewController/releases/download/1.0.4/SRPPlayerViewController.framework.zip "Release"
[6]: https://www.dropbox.com/s/wqmc9zzyzrvel0s/IJKMediaFramework.framewor_k0.7.4.zip?dl=0 "IJKMediaFramework"
