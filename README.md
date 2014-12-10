# SRPMoviePlayerController

基於 [Vitamio 4.2.6](https://github.com/yixia/Vitamio-iOS/releases/tag/v4.2.6) 的線上影片播放器, 支援 TV out, AirPlay.

基本上我是用在我的 App [影音瀏覽器 2.0](https://itunes.apple.com/us/app/ying-yin-liu-lan-qi/id923745389?l=zh&ls=1&mt=8) 來播放 flash 影片用的.

播放格式請參考 Vitamio [官網](https://www.vitamio.org).

>這裡的 AirPlay 是指 User 手動使用內建控制面板切換 AirPlay, 而非在播放器內切換.

## 需求
iOS 8 Later

僅在 iPhone 6 (iOS 8.1.1), iPad 3 (iOS 8.1.1) 測試過.

>使用 AirPlay 時, 在 iPad 3 上效能很差, 但是透過連接線播放就沒問題.  
>而在 iPhone 6 使用 AirPlay, 效果很好.

## 使用
請先下載 [Vitamio 4.2.6](https://github.com/yixia/Vitamio-iOS/releases/tag/v4.2.6), 並[設置](https://github.com/yixia/Vitamio-iOS/blob/master/Doc/Vitamio_SDK_for_iOS_User_Manual_cn.md), 將 SRPMoviePlayerController 目錄拖放置你的專案.

```Objc
SRPMoviePlayerController *mvc = [[SRPMoviePlayerController alloc]init];

mvc.videoURL = url;

[self presentViewController:mvc animated:YES completion:nil];
```

>不要使用 UINavigationController push, 因為 SRPMoviePlayerController 本身有自帶的 UINavigationBar.

## 問題

### 1. 是否能做到播放器內切換 AirPlay 投射到 TV ?

答案是肯定的, 我也時做出來了,只要透過 `AVAudioSessionCategoryPlayAndRecord`
配合 `MPVolumeView.showsRouteButton = YES`, 可以達到 App 裡切換 airPlay 到 TV,  
但是一進入播放器, 聲音的 route 會跑到耳機, 而且 google 後, 利用這個 category  
可能會用 reject 風險, 所以目前的做法是傾向於讓 User 自己向上拖拉控制台切換 AirPlaye.

### 2. 為何不支援背景播放?

因為背景時投射到 TV 的影像不會 Render, 所以我就不支援背景播放了, 如果是純聲音 (Radio App)  
那就考慮使用背景播放跟 Remote Event 控制.

### 其他問題請開 issue

## License

MIT License
