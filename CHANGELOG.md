## 5.4.0
----------------------------------
1. 支持多个播放实例，具体可以参照demo代码`multiple_player_page.dart`
2. 播放器回调添加playerId参数，用于多实例调用的区分
3. 添加`setPlayerView`方法，创建播放器后，需要绑定view到播发器
4. 去除原列表播放器管道，在android和iOS源码层AliListPlayer与AliPlayer公用一个管道
5. `initService`、`getSDKVersion`以及log级别开关等方法改为静态方法，与原生sdk对齐


## 5.2.2
----------------------------------
1. Docking Aliyun Player SDK (PlatForm include Android、iOS)
2. RenderView: Android uses TextureView,iOS uses UIView

