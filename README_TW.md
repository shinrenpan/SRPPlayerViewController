[![LICENSE](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)
[![Donate](https://img.shields.io/badge/Donate-PayPal-yellow.svg?style=flat-square)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=LC58N7VZUST5N)


基於 [ijkplayer k0.4.4.1][1] 的影片播放器, 不帶控制面板.

Online [Demo][2].

![](README/1.png)


# 特色
- 支援外接螢幕.
- 播放格式: 請參考 [ijkplayer][4].
- 播放協定: 請猜考 [ijkplayer][4].


# 安裝
下載最後一個已經編譯完成 [release][5] 版本, 並拖進你的 Project.

並且必須下載已經編譯完成的 [IJKMediaFramework.framework][6] 同樣拖進你的 Project.


# 使用
```objC
SRPPlayerViewController *mvc = [[SRPPlayerViewController alloc]init];
mvc.mediaURL = ...
```

或是繼承 SRPPlayerViewController.






[1]: https://github.com/Bilibili/ijkplayer/releases/tag/k0.4.4.1 "k0.4.4.1"
[2]: https://appetize.io/app/kekyum7wkdtpgn0er6kdnwztk0 "Demo"
[3]: README_TW.md
[4]: https://github.com/Bilibili/ijkplayer "ijkplayer"
[5]: https://github.com/shinrenpan/SRPPlayerViewController/releases "Release"
[6]: https://www.dropbox.com/s/f5s5pggji98p4hi/IJKMediaFramework.framework_k0.4.4.1.zip?dl=0 "IJKMediaFramework"