# l4d2_plugins_coop
+ **求生之路2的一些小插件**
+ 一部分参考各路大佬写（抄）出来的插件，一部分是直接拿的大佬的插件，仅做整理。如果有适合你的，可以随便下载使用
---
+ **give_pill_kit** 开局离开安全屋发药包（没有检测机制，持有还是会再发）
+ **hostname** 根据端口号改服名，显示部分突变模式(不常用的模式没写，仅写了部分战役和生还者)和难度
+ **l4d2_more_medicals** 手动加载多倍医疗，不随人数动态变化，配合投票插件使用（!mmn 2就是2倍医疗包，!mmy 2就是2倍针药）
+ **l4d2_restore_health** 过关回满血，增加一个cvar判定，默认0关闭回血，1为开启回血
+ **l4d2_rpg_tank** 给输入!rpg的生还传送回起点安全屋并生成5个克，更改死门模式，召唤尸潮，并于60秒后处死全员
+ **l4d2_tank_hp** 根据豆瓣酱坦克提示插件修改，配色更符合下面的坦克击杀数据统计，删除随机女巫血量变成固定血量，坦克血量随难度提升降低，平衡各个难度，新增witch惊扰提示
+ **l4d2_text_info** 信息提示，不适用其他服务器
+ **l4d2_unreservelobby** 当第一个玩家进入服务器，移除大厅匹配
+ **l4d_blackandwhile** 添加一些颜色修饰，提示更好看
+ **l4d_tank_damage_announce** 战役用仿zonemod的坦克数据提示，最大支持8人，超过会不显示，仅汉化
+ **server** 服务器部分功能的实现，重启地图，安全屋无敌，自杀，关闭闲置提示，ConVar提示仅管理员可见(IP展示，关闭大厅匹配已移除)
+ **shop** 商店插件说明:  
每关提供几次机会白嫖部分武器，cvar可自行设定每关几次  
!buy !gw打开商店面板  
!chr快速选铁喷，!pum快速选木喷，!uzi快速选uzi，!smg快速选smg  
!ammo补充后备弹夹，cvar设置多长时间补充一次  
增加出门近战发放，读取steamid写入文件，再次进服自动加载之前选择  
增加一个cvar控制开关商店  
2.0新增管理员指令开关商店，!shop off关闭商店，!shop on打开商店，!shop查看当前商店开关情况  
2.1新增白嫖近战菜单  
+ **vote** Anne的投票加载cfg和指令，删除数据库相关功能，仅保留投票和踢人
+ **witch_damage_announce** zonemod的witch伤害提示，和上面tank提示一起使用，配色统一