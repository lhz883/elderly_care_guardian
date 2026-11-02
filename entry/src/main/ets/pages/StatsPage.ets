// 数据统计页

import { Color, FontSize, FontWeight_, Grad, Radius, Shadow_, Space } from '../common/Theme';
import { Responsive } from '../common/Responsive';
import { NavBar } from '../components/NavBar';
import { MockData } from '../common/MockData';
import { WeekBarItem } from '../common/MockData';

type RangeKey = 'day' | 'week' | 'month';

interface RangeItem {
  k: RangeKey;
  label: string;
}

@Entry
@Component
struct StatsPage {
  @StorageLink('currentBreakpoint') bp: string = 'sm';
  @State range: RangeKey = 'week';
  @State hourly: number[] = MockData.hourlyActivity();
  @State weekly: WeekBarItem[] = MockData.weeklyAlerts();

  private ranges: RangeItem[] = [
    { k: 'day', label: '今日' },
    { k: 'week', label: '本周' },
    { k: 'month', label: '本月' }
  ];

  private pm(): number {
    return Responsive.pageMargin(this.bp);
  }

  private maxHourly(): number {
    return Math.max(...this.hourly, 1);
  }

  private maxWeekly(): number {
    return Math.max(...this.weekly.map(w => w.count), 1);
  }

  private totalWeekly(): number {
    return this.weekly.reduce((a, b) => a + b.count, 0);
  }

  private pad(n: number): string {
    return n < 10 ? '0' + n : '' + n;
  }

  private hourGrad(hour: number, v: number): LinearGradientOptions {
    if (v === 0)
      return { angle: 180, colors: [['#E6EDF5', 0.0], ['#E6EDF5', 1.0]] };
    if (hour < 6)
      return Grad.barNight();
    if (hour < 20)
      return Grad.barPrimary();
    return Grad.barEvening();
  }

  @Builder
  kpiCard(cls: string, value: string, label: string, delta: string, deltaColor: string, valueColor: string) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column()
        .width(52)
        .height(52)
        .borderRadius(26)
        .backgroundColor(cls === 'p' ? Color.primary : cls === 'a' ? Color.accent : Color.warning)
        .opacity(0.12)
        .margin({ top: -14, right: -14 })
      Column() {
        Text(value)
          .fontSize(20)
          .fontWeight(FontWeight_.extrabold)
          .fontColor(valueColor)
        Text(label)
          .fontSize(FontSize.caption - 0.5)
          .fontColor(Color.textSecondary)
          .margin({ top: 2 })
        Text(delta)
          .fontSize(FontSize.mini - 0.5)
          .fontWeight(FontWeight_.bold)
          .fontColor(deltaColor)
          .margin({ top: 5 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1)
    .padding(Space.md)
    .backgroundColor(Color.card)
    .borderRadius(Radius.tile)
    .shadow(Shadow_.card())
    .clip(true)
  }

  build() {
    Column() {
      NavBar({
        title: '数据统计', showBack: true, rightText: '导出',
        onRight: () => { this.getUIContext().getPromptAction().showToast({ message: '正在生成周/月报告 PDF…' }); }
      })

      Scroll() {
        Column() {
          // 分段控件
          Row() {
            ForEach(this.ranges, (item: RangeItem) => {
              Text(item.label)
                .fontSize(FontSize.body - 1)
                .fontWeight(this.range === item.k ? FontWeight_.bold : FontWeight_.semibold)
                .fontColor(this.range === item.k ? Color.primaryDark : Color.textSecondary)
                .padding({ top: 7, bottom: 7 })
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .borderRadius(9)
                .backgroundColor(this.range === item.k ? '#FFFFFF' : 'rgba(0,0,0,0)')
                .shadow(this.range === item.k
                  ? { radius: 6, color: 'rgba(15,23,42,0.10)', offsetX: 0, offsetY: 2 }
                  : { radius: 0, color: 'rgba(0,0,0,0)', offsetX: 0, offsetY: 0 })
                .onClick(() => { this.range = item.k; })
            }, (item: RangeItem) => item.k)
          }
          .width('100%')
          .backgroundColor(Color.track)
          .borderRadius(Radius.chip)
          .padding(3)
          .margin({ left: this.pm(), right: this.pm(), top: Space.md - 2, bottom: Space.md - 2 })

          // KPI
          Row({ space: 9 }) {
            this.kpiCard('p', '322', '活动次数', '↑ 8% 较上周', Color.successDark, Color.primaryDark)
            this.kpiCard('a', '7.2', '平均睡眠 (h)', '→ 与上周持平', Color.textTertiary, Color.accentDark)
            this.kpiCard('w', `${this.totalWeekly()}`, '预警事件', '↓ 25% 较上周', Color.successDark, Color.warningDark)
          }
          .width('100%')
          .padding({ left: this.pm(), right: this.pm() })

          // 24 小时活动分布
          Column() {
            Row() {
              Text('24 小时活动分布')
                .fontSize(FontSize.h3)
                .fontWeight(FontWeight_.bold)
                .fontColor(Color.textPrimary)
              Blank()
              Text('按小时聚合')
                .fontSize(FontSize.caption - 0.5)
                .fontColor(Color.textTertiary)
            }
            .width('100%')

            Stack({ alignContent: Alignment.Bottom }) {
              // 网格基线
              Column() {
                ForEach([1, 2, 3], (n: number) => {
                  Column()
                    .width('100%')
                    .layoutWeight(1)
                    .border({ width: { bottom: 1 }, color: 'rgba(148,163,184,0.16)' })
                }, (n: number) => `grid_${n}`)
                Column().width('100%').layoutWeight(1)
              }
              .width('100%')
              .height(112)

              Row() {
                ForEach(this.hourly, (v: number, i: number) => {
                  Column() {
                    Column()
                      .width('100%')
                      .height(Math.max(2, (v / this.maxHourly()) * 108))
                      .borderRadius({ topLeft: 4, topRight: 4, bottomLeft: 2, bottomRight: 2 })
                      .linearGradient(this.hourGrad(i, v))
                  }
                  .layoutWeight(1)
                  .height(112)
                  .justifyContent(FlexAlign.End)
                  .padding({ left: 1.5, right: 1.5 })
                }, (v: number, i: number) => `h_${i}`)
              }
              .width('100%')
              .height(112)
              .alignItems(VerticalAlign.Bottom)
            }
            .width('100%')
            .margin({ top: Space.md - 2 })

            Row() {
              ForEach([0, 4, 8, 12, 16, 20, 23], (h: number) => {
                Text(`${this.pad(h)}:00`)
                  .fontSize(FontSize.mini - 1)
                  .fontColor(Color.textTertiary)
                  .layoutWeight(1)
                  .textAlign(h === 23 ? TextAlign.End : TextAlign.Start)
              }, (h: number) => `x_${h}`)
            }
            .width('100%')
            .margin({ top: 5 })
          }
          .padding(Space.lg - 2)
          .backgroundColor(Color.card)
          .borderRadius(Radius.card)
          .shadow(Shadow_.card())
          .alignItems(HorizontalAlign.Start)
          .margin({ left: this.pm(), right: this.pm(), top: Space.md - 2 })

          // 7 天预警趋势
          Column() {
            Row() {
              Text('近 7 天预警趋势')
                .fontSize(FontSize.h3)
                .fontWeight(FontWeight_.bold)
                .fontColor(Color.textPrimary)
              Blank()
              Text(`共 ${this.totalWeekly()} 次`)
                .fontSize(FontSize.caption - 0.5)
                .fontColor(Color.textTertiary)
            }
            .width('100%')

            Row() {
              ForEach(this.weekly, (w: WeekBarItem) => {
                Column() {
                  Text(`${w.count}`)
                    .fontSize(FontSize.mini)
                    .fontWeight(FontWeight_.bold)
                    .fontColor(Color.textSecondary)
                    .margin({ bottom: Space.xs })
                  Column()
                    .width(22)
                    .height(Math.max(4, (w.count / this.maxWeekly()) * 78))
                    .borderRadius(7)
                    .linearGradient(w.count === 0
                      ? { angle: 180, colors: [['#E6EDF5', 0.0], ['#E6EDF5', 1.0]] }
                      : Grad.barWarning())
                  Text(w.day)
                    .fontSize(FontSize.mini)
                    .fontColor(Color.textTertiary)
                    .margin({ top: Space.xs + 1 })
                }
                .layoutWeight(1)
                .height(118)
                .justifyContent(FlexAlign.End)
              }, (w: WeekBarItem) => w.day)
            }
            .width('100%')
            .margin({ top: 10 })
          }
          .padding(Space.lg - 2)
          .backgroundColor(Color.card)
          .borderRadius(Radius.card)
          .shadow(Shadow_.card())
          .alignItems(HorizontalAlign.Start)
          .margin({ left: this.pm(), right: this.pm(), top: Space.md - 2 })

          // AI 洞察
          Column() {
            Row() {
              SymbolGlyph($r('sys.symbol.star_fill'))
                .fontSize(15)
                .fontColor([Color.accentDark])
              Text('智能洞察')
                .fontSize(FontSize.h3)
                .fontWeight(FontWeight_.extrabold)
                .fontColor(Color.textPrimary)
                .margin({ left: 6 })
            }
            .width('100%')

            Column({ space: 4 }) {
              Text('老人活动高峰在 07-09 时与 17-19 时，与日常作息一致。')
                .fontSize(FontSize.body - 1)
                .fontColor(Color.textPrimary)
                .lineHeight(18)
                .width('100%')
                .padding({ left: 14 })
              Text('周三预警偏多（2 次），建议关注当日社区施工噪音是否影响作息。')
                .fontSize(FontSize.body - 1)
                .fontColor(Color.textPrimary)
                .lineHeight(18)
                .width('100%')
                .padding({ left: 14 })
              Text('客厅温度稳定在 22-25°C，湿度 45-60%，处于舒适区间。')
                .fontSize(FontSize.body - 1)
                .fontColor(Color.textPrimary)
                .lineHeight(18)
                .width('100%')
                .padding({ left: 14 })
            }
            .width('100%')
            .margin({ top: 9 })
          }
          .padding(Space.lg - 2)
          .borderRadius(Radius.card)
          .linearGradient(Grad.heroAccent())
          .shadow({ radius: 14, color: 'rgba(234,88,12,0.12)', offsetX: 0, offsetY: 4 })
          .alignItems(HorizontalAlign.Start)
          .margin({ left: this.pm(), right: this.pm(), top: Space.md - 2, bottom: Space.xxl })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.bg)
  }
}
