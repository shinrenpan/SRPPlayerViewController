[![LICENSE](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
[![Donate](https://img.shields.io/badge/Donate-PayPal-yellow.svg?style=flat-square)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=LC58N7VZUST5N)


基於 [ijkplayer k0.7.4][1] 的播放器 UIViewController.


## 特色
- 支援外接設備全螢幕.
- Media Format: 參考 [ijkplayer][4].
- URL Protocol: 參考 [ijkplayer][4].


## 編譯
- 依照 [ijkplayer-builder][2] 先編譯出 **IJKMediaFramework.framework, libssl.a, libcrypto.a**, 再拖到 ijkplayer 目錄. 

![](README/1.png)

- 執行 build.sh


## 使用
- 將 **IJKMediaFramework.framework, libssl.a, libcrypto.a, SRPPlayerViewController.framework** 拖到你的 Project.
- 在你的 Project 加入 **libz.tbd** 到 `Linked Frameworks and Libraries`.
- 使用 SRPPlayerViewController 或是 subclass 它, 參考 [IPTV]

```objC
SRPPlayerViewController *mvc = [[SRPPlayerViewController alloc]init];
mvc.mediaURL = ...
```





[1]: https://github.com/Bilibili/ijkplayer/releases/tag/k0.7.4 "k0.7.4"
[2]: https://github.com/shinrenpan/ijkplayer-builder
[3]: README_TW.md
[4]: https://github.com/Bilibili/ijkplayer "ijkplayer"
[IPTV]: https://github.com/shinrenpan/IPTV