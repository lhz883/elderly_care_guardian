// 我的
import { Color, FontSize, FontWeight_, Grad, Radius, Shadow_, Space } from '../common/Theme';
import { Responsive } from '../common/Responsive';
import { Session } from '../common/Session';
import { AccountStore, AccountInfo } from '../common/AccountStore';
import { SectionHeader } from '../components/SectionHeader';
import { Medal } from '../components/Medal';
import { MockData } from '../common/MockData';
import { Elder, EmergencyContact } from '../model/Elder';

@Component
export struct ProfilePage {
  @StorageLink('currentBreakpoint') bp: string = 'sm';
  @State elder: Elder = MockData.elder();
  @State notifyAlert: boolean = true;
  @State notifyPush: boolean = true;
  @State notifySound: boolean = true;
  @State distributedSync: boolean = true;
  @State userNick: string = '监护人';
  @State userRelation: string = '儿子';
  @State userPhone: string = '';

  aboutToAppear() {
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined)
      return;
    Session.load(ctx).then((phone: string) => {
      this.userPhone = phone;
      if (phone.length === 0)
        return;
      return AccountStore.findByPhone(ctx, phone).then((acc: AccountInfo | null) => {
        if (acc !== null) {
          this.userNick = acc.nickname;
          this.userRelation = acc.relation;
        }
      });
    });
  }

  private maskedPhone(): string {
    if (this.userPhone.length !== 11)
      return this.userPhone.length > 0 ? this.userPhone : '未绑定';
    return `${this.userPhone.substring(0, 3)}****${this.userPhone.substring(7)}`;
  }

  private pm(): number {
    return Responsive.pageMargin(this.bp);
  }

  private switchAccount(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/LoginPage', params: { switch: '1' } });
  }

  private confirmLogout(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '退出登录',
      message: '退出后将不再接收预警推送，确认退出当前监护人账号？',
      buttons: [
        { text: '取消', color: Color.textSecondary },
        { text: '确认退出', color: Color.critical }
      ]
    }).then((result) => {
      if (result.index === 1) {
        const ctx = this.getUIContext().getHostContext();
        if (ctx === undefined)
          return;
        Session.clear(ctx).then(() => {
          this.getUIContext().getRouter().replaceUrl({ url: 'pages/LoginPage' });
        });
      }
    });
  }

  @Builder
  settingRow(icon: Resource, title: string, sub: string, hasChevron: boolean = true,
             onTap?: () => void, danger: boolean = false) {
    Row() {
      Medal({ variant: danger ? 'softcrit' : 'soft', icon: icon, medalSize: 32 })
        .margin({ right: 11 })
      Column() {
        Text(title)
          .fontSize(FontSize.body + 0.5)
          .fontWeight(FontWeight_.semibold)
          .fontColor(danger ? Color.criticalDark : Color.textPrimary)
        if (sub.length > 0)
          Text(sub)
            .fontSize(FontSize.caption - 0.5)
            .fontColor(Color.textTertiary)
            .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (hasChevron) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(15)
          .fontColor(['#CBD5E1'])
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: Space.lg - 2, right: Space.lg - 2 })
    .backgroundColor(Color.card)
    .onClick(() => {
      if (onTap)
        onTap();
      else
        this.getUIContext().getPromptAction().showToast({ message: title });
    })
  }

  @Builder
  toggleRow(icon: Resource, title: string, sub: string, value: boolean,
            onChange: (v: boolean) => void) {
    Row() {
      Medal({ variant: 'soft', icon: icon, medalSize: 32 })
        .margin({ right: 11 })
      Column() {
        Text(title)
          .fontSize(FontSize.body + 0.5)
          .fontWeight(FontWeight_.semibold)
          .fontColor(Color.textPrimary)
        Text(sub)
          .fontSize(FontSize.caption - 0.5)
          .fontColor(Color.textTertiary)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor(Color.primary)
        .onChange((v: boolean) => { onChange(v); })
    }
    .width('100%')
    .height(56)
    .padding({ left: Space.lg - 2, right: Space.lg - 2 })
    .backgroundColor(Color.card)
  }

  build() {
    Scroll() {
      Column() {
        // 身份卡（渐变）—— 读取当前登录账号信息
        Row() {
          Column() {
            Text(this.userNick.substring(0, 1))
              .fontSize(20)
              .fontWeight(FontWeight_.extrabold)
              .fontColor('#FFFFFF')
          }
          .width(52)
          .height(52)
          .borderRadius(18)
          .justifyContent(FlexAlign.Center)
          .linearGradient(Grad.primary())
          .shadow(Shadow_.medal('rgba(2,132,199,0.35)'))

          Column() {
            Text(this.userNick)
              .fontSize(FontSize.h2)
              .fontWeight(FontWeight_.bold)
              .fontColor(Color.textPrimary)
            Text(`监护人 · ${this.userRelation}`)
              .fontSize(FontSize.caption)
              .fontColor(Color.textSecondary)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: Space.md })

          Column() {
            SymbolGlyph($r('sys.symbol.qrcode'))
              .fontSize(17)
              .fontColor([Color.textSecondary])
          }
          .width(34)
          .height(34)
          .borderRadius(11)
          .backgroundColor('#FFFFFF')
          .justifyContent(FlexAlign.Center)
          .shadow(Shadow_.card())
        }
        .width('100%')
        .padding(Space.lg - 1)
        .borderRadius(22)
        .linearGradient(Grad.heroPrimary())
        .shadow(Shadow_.card())
        .margin({ left: this.pm(), right: this.pm(), top: Space.md - 2 })

        // 守护对象
        SectionHeader({ title: '守护对象' })
        Column() {
          Row() {
            Column() {
              Text(this.elder.name.substring(0, 1))
                .fontSize(17)
                .fontWeight(FontWeight_.extrabold)
                .fontColor('#FFFFFF')
            }
            .width(46)
            .height(46)
            .borderRadius(16)
            .justifyContent(FlexAlign.Center)
            .linearGradient(Grad.accent())
            .shadow(Shadow_.medal('rgba(234,88,12,0.30)'))

            Column() {
              Row() {
                Text(this.elder.name)
                  .fontSize(FontSize.h3)
                  .fontWeight(FontWeight_.bold)
                  .fontColor(Color.textPrimary)
                Text(`${this.elder.age} 岁 · ${this.elder.gender === 'female' ? '女' : '男'}`)
                  .fontSize(FontSize.caption)
                  .fontColor(Color.textSecondary)
                  .margin({ left: 6 })
              }
              Text(this.elder.address)
                .fontSize(FontSize.caption)
                .fontColor(Color.textSecondary)
                .margin({ top: 3 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(`病史：${this.elder.medicalHistory}`)
                .fontSize(FontSize.mini)
                .fontColor(Color.textTertiary)
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .margin({ left: 11 })

            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(16)
              .fontColor(['#CBD5E1'])
          }
          .width('100%')
          .padding(Space.lg - 2)

          Row() {
            Text('紧急联系人')
              .fontSize(FontSize.body)
              .fontWeight(FontWeight_.bold)
              .fontColor(Color.textPrimary)
            Blank()
            Text('管理')
              .fontSize(FontSize.caption)
              .fontWeight(FontWeight_.semibold)
              .fontColor(Color.primaryDark)
              .onClick(() => { this.getUIContext().getPromptAction().showToast({ message: '管理联系人' }); })
          }
          .width('100%')
          .padding({ left: Space.lg - 2, right: Space.lg - 2, bottom: 6 })

          Row({ space: 10 }) {
            ForEach(this.elder.emergencyContacts.slice(0, 3), (c: EmergencyContact) => {
              Column() {
                Column() {
                  Text(c.name.substring(0, 1))
                    .fontSize(FontSize.body + 2)
                    .fontWeight(FontWeight_.extrabold)
                    .fontColor(c.notifyEnabled ? Color.primaryDark : Color.textSecondary)
                }
                .width(40)
                .height(40)
                .borderRadius(14)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(c.notifyEnabled ? Color.primaryLight : '#F1F5F9')

                Text(c.relation)
                  .fontSize(FontSize.mini)
                  .fontColor(Color.textSecondary)
                  .margin({ top: Space.xs })
                Text(c.phone)
                  .fontSize(FontSize.mini - 1)
                  .fontColor(Color.textTertiary)
              }
              .layoutWeight(1)
              .onClick(() => {
                this.getUIContext().getPromptAction().showToast({ message: `呼叫 ${c.name} · ${c.phone}` });
              })
            }, (c: EmergencyContact) => c.id)
          }
          .width('100%')
          .padding({ left: Space.lg - 2, right: Space.lg - 2, bottom: Space.lg - 2 })
        }
        .backgroundColor(Color.card)
        .borderRadius(Radius.card)
        .shadow(Shadow_.card())
        .margin({ left: this.pm(), right: this.pm() })

        // 功能
        SectionHeader({ title: '功能' })
        Column() {
          this.settingRow($r('sys.symbol.clock_fill'), '安全日志', '查看所有历史事件', true,
            () => { this.getUIContext().getRouter().pushUrl({ url: 'pages/LogPage' }); })
          Divider().color('#F1F5F9').margin({ left: 45 })
          this.settingRow($r('sys.symbol.gearshape'), '设备管理', `${MockData.sensors().length} 台设备`, true,
            () => { this.getUIContext().getRouter().pushUrl({ url: 'pages/DevicePage' }); })
          Divider().color('#F1F5F9').margin({ left: 45 })
          this.settingRow($r('sys.symbol.waveform'), '数据统计', '活动趋势 · 周月报告', true,
            () => { this.getUIContext().getRouter().pushUrl({ url: 'pages/StatsPage' }); })
        }
        .backgroundColor(Color.card)
        .borderRadius(Radius.card)
        .shadow(Shadow_.card())
        .clip(true)
        .margin({ left: this.pm(), right: this.pm() })

        // 账号安全
        SectionHeader({ title: '账号安全' })
        Column() {
          this.settingRow($r('sys.symbol.phone_fill'), '绑定手机号', this.maskedPhone(), false)
          Divider().color('#F1F5F9').margin({ left: 45 })
          this.settingRow($r('sys.symbol.gearshape'), '修改密码', '校验旧密码后设置新密码', true,
            () => { this.getUIContext().getRouter().pushUrl({ url: 'pages/ChangePwdPage' }); })
          Divider().color('#F1F5F9').margin({ left: 45 })
          this.settingRow($r('sys.symbol.person_2_fill'), '切换账号', '保留登录记录，快速切换其他监护人账号', true,
            () => { this.switchAccount(); })
          Divider().color('#F1F5F9').margin({ left: 45 })
          this.settingRow($r('sys.symbol.xmark_circle'), '注销账号', '永久删除账号与绑定关系，不可恢复', true,
            () => { this.getUIContext().getRouter().pushUrl({ url: 'pages/CancelAccountPage' }); }, true)
        }
        .backgroundColor(Color.card)
        .borderRadius(Radius.card)
        .shadow(Shadow_.card())
        .clip(true)
        .margin({ left: this.pm(), right: this.pm() })

        // 通知
        SectionHeader({ title: '通知' })
        Column() {
          this.toggleRow($r('sys.symbol.bell_fill'), '紧急预警通知',
            '包括 SOS / 长时间无活动 / 环境异常',
            this.notifyAlert, (v: boolean) => { this.notifyAlert = v; })
          Divider().color('#F1F5F9').margin({ left: 45 })
          this.toggleRow($r('sys.symbol.paperplane_fill'), '推送至其他终端',
            '同步给子女 / 社区网格员',
            this.notifyPush, (v: boolean) => { this.notifyPush = v; })
          Divider().color('#F1F5F9').margin({ left: 45 })
          this.toggleRow($r('sys.symbol.message_fill'), '声音与振动',
            '收到预警时播放提示音并振动',
            this.notifySound, (v: boolean) => { this.notifySound = v; })
        }
        .backgroundColor(Color.card)
        .borderRadius(Radius.card)
        .shadow(Shadow_.card())
        .clip(true)
        .margin({ left: this.pm(), right: this.pm() })

        // 分布式协同
        SectionHeader({ title: '多终端协同', subtitle: 'OpenHarmony 分布式能力' })
        Column() {
          this.toggleRow($r('sys.symbol.square_grid_2x2'), '跨设备预警同步',
            '将预警实时流转至已登录的平板 / 智慧屏',
            this.distributedSync, (v: boolean) => { this.distributedSync = v; })
          Divider().color('#F1F5F9').margin({ left: 45 })
          this.settingRow($r('sys.symbol.person_2_fill'), '协同成员',
            '儿子（李强）· 女儿（李红）· 文化路社区')
        }
        .backgroundColor(Color.card)
        .borderRadius(Radius.card)
        .shadow(Shadow_.card())
        .clip(true)
        .margin({ left: this.pm(), right: this.pm() })

        // 关于
        SectionHeader({ title: '关于' })
        Column() {
          this.settingRow($r('sys.symbol.info_circle'), '版本信息', '颐养守护 v1.0.0（Build 20261012）')
          Divider().color('#F1F5F9').margin({ left: 45 })
          this.settingRow($r('sys.symbol.doc_text'), '用户协议与隐私政策', '')
          Divider().color('#F1F5F9').margin({ left: 45 })
          this.settingRow($r('sys.symbol.questionmark_circle'), '帮助与反馈', '')
        }
        .backgroundColor(Color.card)
        .borderRadius(Radius.card)
        .shadow(Shadow_.card())
        .clip(true)
        .margin({ left: this.pm(), right: this.pm(), bottom: Space.xxl })

        // 退出登录
        Row() {
          Image($r('app.media.ic_logout'))
            .width(15)
            .height(15)
          Text('退出登录')
            .fontSize(FontSize.body + 1)
            .fontWeight(FontWeight_.bold)
            .fontColor(Color.criticalDark)
            .margin({ left: 6 })
        }
        .width('100%')
        .height(50)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.card)
        .borderRadius(Radius.button)
        .border({ width: 1.5, color: Color.criticalLight })
        .shadow(Shadow_.card())
        .margin({ left: this.pm(), right: this.pm() })
        .onClick(() => { this.confirmLogout(); })

        Column().height(56)
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.bg)
    .scrollBar(BarState.Off)
  }
}
