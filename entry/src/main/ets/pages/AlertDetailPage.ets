import { Color, FontSize, FontWeight_, Grad, Radius, Shadow_, Space } from '../common/Theme';
import { Responsive } from '../common/Responsive';
import { LevelBadge } from '../components/LevelBadge';
import { Medal } from '../components/Medal';
import { PrimaryButton, SecondaryButton } from '../components/Buttons';
import { AlertEvent, AlertMeta, DispositionType, TimelineItem } from '../model/AlertEvent';
import { SensorMeta } from '../model/Sensor';
import { MockData } from '../common/MockData';
import { DateUtil } from '../common/DateUtil';

interface DispositionOption {
  key: DispositionType;
  label: string;
  icon: Resource;
}

@Entry
@Component
struct AlertDetailPage {
  @StorageLink('alerts') alerts: AlertEvent[] = [];
  @StorageLink('currentBreakpoint') bp: string = 'sm';
  @State alert: AlertEvent = new AlertEvent();
  @State selectedDisposition: DispositionType | null = null;
  @State note: string = '';
  @State submitting: boolean = false;
  @State elapsedSec: number = 0;

  private dispositionOptions: DispositionOption[] = [
    { key: 'called_elder', label: '已电话联系老人', icon: $r('sys.symbol.phone_fill') },
    { key: 'contacted_family', label: '已联系家属', icon: $r('sys.symbol.person_2_fill') },
    { key: 'contacted_community', label: '已联系社区网格员', icon: $r('sys.symbol.house_fill') },
    { key: 'called_120', label: '已呼叫 120', icon: $r('sys.symbol.cross_case_fill') },
    { key: 'called_119', label: '已呼叫 119', icon: $r('sys.symbol.flame_fill') },
    { key: 'on_site', label: '已上门查看', icon: $r('sys.symbol.person_fill') },
    { key: 'false_alarm', label: '标记为误报', icon: $r('sys.symbol.xmark_circle') }
  ];

  aboutToAppear() {
    if (this.alerts.length === 0)
      AppStorage.setOrCreate<AlertEvent[]>('alerts', MockData.alerts());
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>;
    const id = params && params.alertId ? params.alertId : '';
    const found = this.alerts.find(a => a.id === id);
    this.alert = found ?? MockData.alerts()[0];
    setInterval(() => {
      this.elapsedSec = Math.floor((Date.now() - this.alert.createdAt) / 1000);
    }, 1000);
  }

  private pm(): number {
    return Responsive.pageMargin(this.bp);
  }

  private elapsedText(): string {
    const s = this.elapsedSec;
    const m = Math.floor(s / 60);
    const sec = s % 60;
    if (m >= 60) {
      const h = Math.floor(m / 60);
      return `${h}:${DateUtil.pad(m % 60)}:${DateUtil.pad(sec)}`;
    }
    return `${DateUtil.pad(m)}:${DateUtil.pad(sec)}`;
  }

  private submitVariant(): string {
    if (this.alert.level === 'critical')
      return 'critical';
    if (this.alert.level === 'high')
      return 'warning';
    return 'primary';
  }

  private submit() {
    if (this.selectedDisposition === null) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: '请选择处置方式' });
      } catch (err) {
        // 忽略 toast 失败
      }
      return;
    }
    this.submitting = true;
    setTimeout(() => {
      const idx = this.alerts.findIndex(a => a.id === this.alert.id);
      if (idx >= 0) {
        const updated = this.alerts[idx];
        updated.status = this.selectedDisposition === 'false_alarm' ? 'false_alarm' : 'closed';
        updated.disposition = this.selectedDisposition;
        updated.dispositionNote = this.note;
        updated.closedAt = Date.now();
        updated.handlerName = '李强（本人）';
        const t = new TimelineItem();
        t.time = Date.now();
        t.actor = '李强（本人）';
        t.action = AlertMeta.dispositionLabel(this.selectedDisposition!);
        t.note = this.note;
        updated.timeline.push(t);
        this.alerts[idx] = updated;
        AppStorage.setOrCreate<AlertEvent[]>('alerts', this.alerts.slice());
        this.alert = updated;
      }
      this.submitting = false;
      this.getUIContext().getPromptAction().showToast({ message: '处置已归档，安全日志已更新' });
      setTimeout(() => {
        this.getUIContext().getRouter().back();
      }, 800);
    }, 800);
  }

  @Builder
  contactAction(variant: string, icon: Resource, label: string, sub: string, onTap: () => void) {
    Column() {
      Medal({ variant: variant, icon: icon, medalSize: 34 })
      Text(label)
        .fontSize(FontSize.caption)
        .fontWeight(FontWeight_.bold)
        .fontColor(Color.textPrimary)
        .margin({ top: 5 })
      Text(sub)
        .fontSize(FontSize.mini - 1)
        .fontColor(Color.textTertiary)
        .margin({ top: 1 })
    }
    .layoutWeight(1)
    .padding({ top: Space.md - 1, bottom: Space.md - 1 })
    .backgroundColor(Color.card)
    .borderRadius(Radius.button)
    .shadow(Shadow_.card())
    .onClick(onTap)
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(22)
            .fontColor([Color.textPrimary])
        }
        .width(42)
        .height(42)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.getUIContext().getRouter().back())

        Text('预警详情')
          .fontSize(15)
          .fontWeight(FontWeight_.bold)
          .fontColor(Color.textPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row().width(42).height(42)
      }
      .width('100%')
      .height(50)
      .backgroundColor('rgba(255,255,255,0.94)')
      .backdropBlur(12)
      .border({ width: { bottom: 1 }, color: Color.border })

      Scroll() {
        Column() {
          Column() {
            Row() {
              LevelBadge({ level: this.alert.level })
              Blank()
              if (this.alert.status === 'pending') {
                Row() {
                  SymbolGlyph($r('sys.symbol.clock_fill'))
                    .fontSize(11)
                    .fontColor([Color.criticalDark])
                  Text(`已过去 ${this.elapsedText()}`)
                    .fontSize(FontSize.caption - 0.5)
                    .fontWeight(FontWeight_.extrabold)
                    .fontColor(Color.criticalDark)
                    .margin({ left: Space.xs })
                }
                .padding({ left: 9, right: 9, top: 4, bottom: 4 })
                .backgroundColor('#FFFFFF')
                .borderRadius(Radius.pill)
                .shadow({ radius: 6, color: 'rgba(220,38,38,0.18)', offsetX: 0, offsetY: 2 })
              }
              else
                Text(AlertMeta.statusLabel(this.alert.status))
                  .fontSize(FontSize.caption)
                  .fontColor(Color.textSecondary)
            }
            .width('100%')

            Text(this.alert.title)
              .fontSize(FontSize.h1)
              .fontWeight(FontWeight_.extrabold)
              .fontColor(Color.textPrimary)
              .margin({ top: 10 })

            Row() {
              SymbolGlyph(SensorMeta.icon(this.alert.sensorType))
                .fontSize(11)
                .fontColor([Color.textSecondary])
              Text(`${this.alert.sensorName} · ${this.alert.location}`)
                .fontSize(FontSize.caption - 0.5)
                .fontColor(Color.textSecondary)
                .margin({ left: Space.xs, right: Space.md })
              SymbolGlyph($r('sys.symbol.calendar'))
                .fontSize(11)
                .fontColor([Color.textSecondary])
              Text(DateUtil.formatDateTime(this.alert.createdAt))
                .fontSize(FontSize.caption - 0.5)
                .fontColor(Color.textSecondary)
                .margin({ left: Space.xs })
            }
            .width('100%')
            .margin({ top: 7 })

            Text(this.alert.description)
              .fontSize(FontSize.body)
              .fontColor(Color.textPrimary)
              .lineHeight(19)
              .margin({ top: 10 })

            if (this.alert.pushedTo.length > 0) {
              Row() {
                SymbolGlyph($r('sys.symbol.paperplane_fill'))
                  .fontSize(11)
                  .fontColor([Color.primaryDark])
                Text('已推送：')
                  .fontSize(FontSize.mini)
                  .fontColor(Color.textSecondary)
                  .margin({ left: Space.xs })
                Text(this.alert.pushedTo.join(' · '))
                  .fontSize(FontSize.mini)
                  .fontColor(Color.textSecondary)
                  .layoutWeight(1)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding({ left: 10, right: 10, top: 8, bottom: 8 })
              .backgroundColor('#FFFFFF')
              .borderRadius(Radius.chip)
              .shadow(Shadow_.card())
              .margin({ top: 10 })
            }
          }
          .padding(Space.lg - 1)
          .width('100%')
          .borderRadius(22)
          .linearGradient(Grad.heroCritical())
          .shadow(Shadow_.pop('rgba(220,38,38,0.12)'))
          .alignItems(HorizontalAlign.Start)
          .margin({ left: this.pm(), right: this.pm(), top: Space.md - 2 })

          // ============= 快速联系 =============
          Column() {
            Text('快速联系')
              .fontSize(FontSize.h3)
              .fontWeight(FontWeight_.bold)
              .fontColor(Color.textPrimary)
              .margin({ bottom: Space.md - 1 })

            Row({ space: Space.sm }) {
              this.contactAction('pri', $r('sys.symbol.phone_fill'), '老人', '138****6621',
                () => { this.getUIContext().getPromptAction().showToast({ message: '正在呼叫老人…' }); })
              this.contactAction('acc', $r('sys.symbol.person_2_fill'), '家属', '李强 · 儿子',
                () => { this.getUIContext().getPromptAction().showToast({ message: '正在呼叫家属…' }); })
              this.contactAction('ok', $r('sys.symbol.house_fill'), '社区', '文化路社区',
                () => { this.getUIContext().getPromptAction().showToast({ message: '正在呼叫社区网格员…' }); })
              this.contactAction('crit', $r('sys.symbol.cross_case_fill'), '120', '急救',
                () => {
                  this.getUIContext().getPromptAction().showDialog({
                    title: '呼叫 120',
                    message: '确认呼叫急救电话？',
                    buttons: [
                      { text: '取消', color: Color.textSecondary },
                      { text: '确认呼叫', color: Color.critical }
                    ]
                  });
                })
            }
            .width('100%')
          }
          .padding(Space.lg - 2)
          .width('100%')
          .backgroundColor(Color.card)
          .borderRadius(Radius.card)
          .shadow(Shadow_.card())
          .alignItems(HorizontalAlign.Start)
          .margin({ left: this.pm(), right: this.pm(), top: Space.md - 2 })

          // ============= 处置表单 =============
          if (this.alert.status === 'pending' || this.alert.status === 'processing') {
            Column() {
              Row() {
                Text('处置结果')
                  .fontSize(FontSize.h3)
                  .fontWeight(FontWeight_.bold)
                  .fontColor(Color.textPrimary)
                Text('* 必填')
                  .fontSize(FontSize.mini)
                  .fontWeight(FontWeight_.bold)
                  .fontColor(Color.criticalDark)
                  .margin({ left: 6 })
              }
              .width('100%')

              Column({ space: 7 }) {
                ForEach(this.dispositionOptions, (opt: DispositionOption) => {
                  Row() {
                    Stack() {
                      Column()
                        .width(18)
                        .height(18)
                        .borderRadius(9)
                        .backgroundColor(this.selectedDisposition === opt.key ? '#FFFFFF' : '#FFFFFF')
                        .border({
                          width: 2,
                          color: this.selectedDisposition === opt.key ? 'rgba(0,0,0,0)' : '#CBD5E1'
                        })
                      if (this.selectedDisposition === opt.key) {
                        Column()
                          .width(18)
                          .height(18)
                          .borderRadius(9)
                          .linearGradient(Grad.primary())
                        SymbolGlyph($r('sys.symbol.checkmark'))
                          .fontSize(10)
                          .fontColor(['#FFFFFF'])
                      }
                    }
                    .width(18)
                    .height(18)
                    .margin({ right: 9 })

                    Column() {
                      SymbolGlyph(opt.icon)
                        .fontSize(13)
                        .fontColor([this.selectedDisposition === opt.key ? Color.primaryDark : Color.textSecondary])
                    }
                    .width(26)
                    .height(26)
                    .borderRadius(9)
                    .backgroundColor(this.selectedDisposition === opt.key ? Color.primaryLight : '#F1F5F9')
                    .justifyContent(FlexAlign.Center)
                    .margin({ right: Space.sm })

                    Text(opt.label)
                      .fontSize(FontSize.body)
                      .fontWeight(this.selectedDisposition === opt.key
                        ? FontWeight_.bold : FontWeight_.regular)
                      .fontColor(this.selectedDisposition === opt.key
                        ? Color.textPrimary : Color.textSecondary)
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .height(46)
                  .padding({ left: Space.md, right: Space.md })
                  .borderRadius(Radius.button)
                  .linearGradient(this.selectedDisposition === opt.key
                    ? Grad.heroPrimary()
                    : { angle: 135, colors: [[Color.card, 0.0], [Color.card, 1.0]] })
                  .border({
                    width: 1.5,
                    color: this.selectedDisposition === opt.key ? Color.primary : Color.border
                  })
                  .onClick(() => { this.selectedDisposition = opt.key; })
                }, (opt: DispositionOption) => opt.key)
              }
              .width('100%')
              .margin({ top: 10 })

              Text('补充说明（选填）')
                .fontSize(FontSize.caption)
                .fontColor(Color.textSecondary)
                .margin({ top: Space.lg - 2, bottom: 6 })

              TextArea({
                placeholder: '请简要说明处置过程，例如：电话联系老人，反馈是起床倒水，无异常。',
                text: this.note
              })
                .width('100%')
                .height(96)
                .fontSize(FontSize.caption + 0.5)
                .backgroundColor('#F8FAFC')
                .borderRadius(Radius.button)
                .border({ width: 1.5, color: '#CBD5E1', style: BorderStyle.Dashed })
                .padding(Space.md)
                .onChange((v: string) => { this.note = v; })
            }
            .padding(Space.lg - 2)
            .width('100%')
            .backgroundColor(Color.card)
            .borderRadius(Radius.card)
            .shadow(Shadow_.card())
            .alignItems(HorizontalAlign.Start)
            .margin({ left: this.pm(), right: this.pm(), top: Space.md - 2 })
          } else {
            Column() {
              Text('处置结果')
                .fontSize(FontSize.h3)
                .fontWeight(FontWeight_.bold)
                .fontColor(Color.textPrimary)

              Row() {
                SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
                  .fontSize(20)
                  .fontColor([Color.successDark])
                Column() {
                  Text(this.alert.disposition !== null
                    ? AlertMeta.dispositionLabel(this.alert.disposition!)
                    : '--')
                    .fontSize(FontSize.body + 1)
                    .fontWeight(FontWeight_.bold)
                    .fontColor(Color.textPrimary)
                  Text(`处置人：${this.alert.handlerName} · ${DateUtil.formatDateTime(this.alert.closedAt)}`)
                    .fontSize(FontSize.caption)
                    .fontColor(Color.textSecondary)
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({ left: Space.md })
              }
              .width('100%')
              .padding(Space.md)
              .backgroundColor(Color.successLight)
              .borderRadius(Radius.button)
              .margin({ top: 10 })

              if (this.alert.dispositionNote.length > 0) {
                Text(this.alert.dispositionNote)
                  .fontSize(FontSize.body)
                  .fontColor(Color.textPrimary)
                  .lineHeight(19)
                  .margin({ top: Space.md - 2 })
              }
            }
            .padding(Space.lg - 2)
            .width('100%')
            .backgroundColor(Color.card)
            .borderRadius(Radius.card)
            .shadow(Shadow_.card())
            .alignItems(HorizontalAlign.Start)
            .margin({ left: this.pm(), right: this.pm(), top: Space.md - 2 })
          }

          // ============= 时间线 =============
          Column() {
            Text('事件时间线')
              .fontSize(FontSize.h3)
              .fontWeight(FontWeight_.bold)
              .fontColor(Color.textPrimary)
              .margin({ bottom: Space.md })

            ForEach(this.alert.timeline, (t: TimelineItem, idx: number) => {
              Row() {
                Column() {
                  Column()
                    .width(idx === this.alert.timeline.length - 1 ? 9 : 9)
                    .height(9)
                    .borderRadius(4.5)
                    .linearGradient(idx === this.alert.timeline.length - 1
                      ? Grad.primary()
                      : { angle: 135, colors: [['#CBD5E1', 0.0], ['#CBD5E1', 1.0]] })
                    .shadow(idx === this.alert.timeline.length - 1
                      ? { radius: 0, color: 'rgba(14,165,233,0.25)', offsetX: 0, offsetY: 0 }
                      : { radius: 0, color: 'rgba(0,0,0,0)', offsetX: 0, offsetY: 0 })
                  if (idx < this.alert.timeline.length - 1) {
                    Column()
                      .width(2)
                      .height(26)
                      .backgroundColor(Color.border)
                      .margin({ top: 4 })
                  }
                }
                .width(16)
                .alignItems(HorizontalAlign.Center)

                Column() {
                  Row() {
                    Text(t.action)
                      .fontSize(FontSize.body - 0.5)
                      .fontWeight(FontWeight_.bold)
                      .fontColor(Color.textPrimary)
                      .layoutWeight(1)
                    Text(DateUtil.formatTime(t.time))
                      .fontSize(FontSize.caption - 0.5)
                      .fontColor(Color.textTertiary)
                  }
                  .width('100%')

                  Row() {
                    Text(t.actor)
                      .fontSize(FontSize.caption - 0.5)
                      .fontColor(Color.textSecondary)
                    if (t.note.length > 0) {
                      Text(` · ${t.note}`)
                        .fontSize(FontSize.caption - 0.5)
                        .fontColor(Color.textTertiary)
                        .layoutWeight(1)
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                  }
                  .width('100%')
                  .margin({ top: 2 })
                }
                .layoutWeight(1)
                .padding({ left: 9, bottom: Space.md })
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
            }, (t: TimelineItem, idx: number) => `${idx}_${t.time}`)
          }
          .padding(Space.lg - 2)
          .width('100%')
          .backgroundColor(Color.card)
          .borderRadius(Radius.card)
          .shadow(Shadow_.card())
          .alignItems(HorizontalAlign.Start)
          .margin({ left: this.pm(), right: this.pm(), top: Space.md - 2, bottom: Space.xxl })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 底部行动区
      if (this.alert.status === 'pending' || this.alert.status === 'processing') {
        Row({ space: 10 }) {
          Column() {
            SecondaryButton({
              label: '暂不处理',
              color: Color.textSecondary,
              onClick_: () => { this.getUIContext().getRouter().back(); }
            })
          }
          .width(104)

          Column() {
            PrimaryButton({
              label: this.alert.status === 'pending' ? '确认处置并归档' : '更新处置',
              loading: this.submitting,
              disabled: this.selectedDisposition === null,
              variant: this.submitVariant(),
              onClick_: () => { this.submit(); }
            })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: this.pm(), right: this.pm(), top: 10, bottom: 10 })
        .backgroundColor('rgba(255,255,255,0.96)')
        .backdropBlur(12)
        .border({ width: { top: 1 }, color: Color.border })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.bg)
  }
}
