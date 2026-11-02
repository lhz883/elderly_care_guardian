import { Color, FontSize, FontWeight_, Grad, Shadow_ } from '../common/Theme';
import { Responsive } from '../common/Responsive';
import { HomePage } from './HomePage';
import { MonitorPage } from './MonitorPage';
import { AlertListPage } from './AlertListPage';
import { ProfilePage } from './ProfilePage';
import { SosFloatingButton } from '../components/SosFloatingButton';
import { MockData } from '../common/MockData';
import { AlertEvent } from '../model/AlertEvent';

@Entry
@Component
struct Index {
  @StorageLink('currentTabIndex') currentIndex: number = 0;
  @StorageLink('alerts') alerts: AlertEvent[] = [];

  aboutToAppear() {
    Responsive.init(this.getUIContext());
    AppStorage.setOrCreate<AlertEvent[]>('alerts', MockData.alerts());
    AppStorage.setOrCreate('currentTabIndex', 0);
  }

  @Builder
  tabBarBuilder(index: number, label: string, icon: Resource, iconActive: Resource,
                badge: number = 0) {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        SymbolGlyph(this.currentIndex === index ? iconActive : icon)
          .fontSize(21)
          .fontColor([this.currentIndex === index ? Color.primaryDark : Color.textTertiary])
        if (badge > 0) {
          Text(badge > 99 ? '99+' : badge.toString())
            .fontSize(8.5)
            .fontWeight(FontWeight_.extrabold)
            .fontColor('#FFFFFF')
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
            .borderRadius(999)
            .linearGradient(Grad.critical())
            .shadow({ radius: 6, color: 'rgba(220,38,38,0.4)', offsetX: 0, offsetY: 2 })
            .margin({ top: -4, right: -9 })
        }
      }
      Text(label)
        .fontSize(FontSize.mini)
        .fontColor(this.currentIndex === index ? Color.primaryDark : Color.textTertiary)
        .fontWeight(this.currentIndex === index ? FontWeight_.bold : FontWeight_.regular)
        .margin({ top: 3 })
      Column()
        .width(this.currentIndex === index ? 14 : 0)
        .height(3)
        .borderRadius(2)
        .linearGradient(Grad.primary())
        .margin({ top: 3 })
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = index;
      AppStorage.setOrCreate('currentTabIndex', index);
    })
  }

  private pendingCount(): number {
    return this.alerts.filter(a => a.status === 'pending').length;
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() { HomePage() }
          .tabBar(this.tabBarBuilder(0, '首页',
            $r('sys.symbol.house'), $r('sys.symbol.house_fill')))

        TabContent() { MonitorPage() }
          .tabBar(this.tabBarBuilder(1, '监测',
            $r('sys.symbol.waveform'), $r('sys.symbol.waveform')))

        TabContent() { AlertListPage() }
          .tabBar(this.tabBarBuilder(2, '预警',
            $r('sys.symbol.bell'), $r('sys.symbol.bell_fill'), this.pendingCount()))

        TabContent() { ProfilePage() }
          .tabBar(this.tabBarBuilder(3, '我的',
            $r('sys.symbol.person'), $r('sys.symbol.person_fill')))
      }
      .barHeight(62)
      .barBackgroundColor('rgba(255,255,255,0.96)')
      .scrollable(false)
      .animationDuration(220)
      .onChange((idx: number) => {
        this.currentIndex = idx;
        AppStorage.setOrCreate('currentTabIndex', idx);
      })
      .width('100%')
      .height('100%')
      .backgroundColor(Color.bg)

      Column() {
        SosFloatingButton({
          visible: true,
          onTrigger: () => {
            this.getUIContext().getPromptAction().showToast({ message: 'SOS 已推送 · 本地声光报警器已启动' });
          }
        })
      }
      .margin({ right: 14, bottom: 80 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.bg)
  }
}
