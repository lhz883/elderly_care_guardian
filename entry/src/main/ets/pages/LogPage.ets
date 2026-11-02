// 安全日志页
import { Color, FontSize, FontWeight_, Grad, Radius, Shadow_, Space } from '../common/Theme';
import { Responsive } from '../common/Responsive';
import { NavBar } from '../components/NavBar';
import { LevelBadge } from '../components/LevelBadge';
import { EmptyState } from '../components/EmptyState';
import { MockData } from '../common/MockData';
import { AlertEvent, AlertMeta } from '../model/AlertEvent';
import { DateUtil } from '../common/DateUtil';

interface DayGroup {
  date: string;
  items: AlertEvent[];
}

@Entry
@Component
struct LogPage {
  @StorageLink('currentBreakpoint') bp: string = 'sm';
  @State alerts: AlertEvent[] = MockData.alerts();
  @State filterKeyword: string = '';

  private pm(): number {
    return Responsive.pageMargin(this.bp);
  }

  private groups(): DayGroup[] {
    const filtered = this.filterKeyword.length === 0
      ? this.alerts
      : this.alerts.filter(a =>
          a.title.includes(this.filterKeyword) ||
          a.sensorName.includes(this.filterKeyword) ||
          a.location.includes(this.filterKeyword));

    const map = new Map<string, AlertEvent[]>();
    filtered.slice()
      .sort((a, b) => b.createdAt - a.createdAt)
      .forEach(a => {
        const key = DateUtil.formatDate(a.createdAt);
        const arr = map.get(key) ?? [];
        arr.push(a);
        map.set(key, arr);
      });

    const result: DayGroup[] = [];
    map.forEach((v: AlertEvent[], k: string) => {
      result.push({ date: k, items: v });
    });
    return result;
  }

  build() {
    Column() {
      NavBar({ title: '安全日志', showBack: true })

      // 搜索
      Row() {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(14)
          .fontColor([Color.textTertiary])
          .margin({ right: Space.sm })
        TextInput({ placeholder: '搜索事件 / 传感器 / 位置', text: this.filterKeyword })
          .fontSize(FontSize.body - 0.5)
          .backgroundColor('rgba(0,0,0,0)')
          .layoutWeight(1)
          .onChange((v: string) => { this.filterKeyword = v; })
      }
      .width('100%')
      .height(40)
      .padding({ left: Space.md, right: Space.md })
      .backgroundColor(Color.card)
      .borderRadius(Radius.button)
      .border({ width: 1.5, color: Color.border })
      .margin({ left: this.pm(), right: this.pm(), top: 10, bottom: 6 })

      Row() {
        Text(`共 ${this.alerts.length} 条事件`)
          .fontSize(FontSize.caption)
          .fontColor(Color.textSecondary)
        Blank()
        Text('按日期倒序')
          .fontSize(FontSize.caption)
          .fontColor(Color.textTertiary)
      }
      .width('100%')
      .padding({ left: this.pm() + 2, right: this.pm() + 2, top: 2, bottom: 6 })

      if (this.groups().length === 0)
        EmptyState({ title: '无匹配日志', description: '换个关键词试试' })
      else {
        List({ space: Space.md - 2 }) {
          ForEach(this.groups(), (g: DayGroup) => {
            ListItem() {
              Column() {
                Row() {
                  Text(g.date)
                    .fontSize(FontSize.body + 0.5)
                    .fontWeight(FontWeight_.extrabold)
                    .fontColor(Color.textPrimary)
                  Blank()
                  Text(`${g.items.length} 条`)
                    .fontSize(FontSize.caption - 0.5)
                    .fontColor(Color.textTertiary)
                }
                .width('100%')
                .padding({ left: this.pm() + 2, right: this.pm() + 2, bottom: 7 })

                Column() {
                  ForEach(g.items, (a: AlertEvent, idx: number) => {
                    Row() {
                      Column() {
                        Column()
                          .width(9)
                          .height(9)
                          .borderRadius(4.5)
                          .linearGradient(Grad.level(a.level))
                        if (idx < g.items.length - 1) {
                          Column()
                            .width(2)
                            .height(20)
                            .backgroundColor(Color.border)
                            .margin({ top: 4 })
                        }
                      }
                      .width(16)
                      .alignItems(HorizontalAlign.Center)

                      Column() {
                        Row() {
                          Text(a.title)
                            .fontSize(FontSize.body)
                            .fontWeight(FontWeight_.bold)
                            .fontColor(Color.textPrimary)
                            .layoutWeight(1)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                          Text(DateUtil.formatTime(a.createdAt))
                            .fontSize(FontSize.caption - 0.5)
                            .fontColor(Color.textTertiary)
                        }
                        .width('100%')

                        Row() {
                          LevelBadge({ level: a.level, small: true })
                          Text(AlertMeta.statusLabel(a.status))
                            .fontSize(FontSize.mini)
                            .fontColor(Color.textSecondary)
                            .margin({ left: 6 })
                          Blank()
                          if (a.disposition !== null && a.disposition !== undefined)
                            Text(`✓ ${AlertMeta.dispositionLabel(a.disposition)}`)
                              .fontSize(FontSize.mini)
                              .fontWeight(FontWeight_.semibold)
                              .fontColor(Color.successDark)
                        }
                        .width('100%')
                        .margin({ top: 5 })

                        Text(`${a.sensorName} · ${a.location}`)
                          .fontSize(FontSize.caption - 0.5)
                          .fontColor(Color.textSecondary)
                          .margin({ top: Space.xs })
                      }
                      .layoutWeight(1)
                      .padding({ left: 9, bottom: Space.md })
                      .alignItems(HorizontalAlign.Start)
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Top)
                    .onClick(() => {
                      this.getUIContext().getRouter().pushUrl({
                        url: 'pages/AlertDetailPage',
                        params: { alertId: a.id }
                      });
                    })
                  }, (a: AlertEvent) => a.id)
                }
                .padding(Space.md + 1)
                .backgroundColor(Color.card)
                .borderRadius(Radius.tile)
                .shadow(Shadow_.card())
                .margin({ left: this.pm(), right: this.pm() })
              }
              .width('100%')
            }
          }, (g: DayGroup) => g.date)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ top: 2, bottom: Space.xxl })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.bg)
  }
}
