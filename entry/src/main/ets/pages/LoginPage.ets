// 登录页
import { Color, FontSize, FontWeight_, Grad, Radius, Shadow_, Space } from '../common/Theme';
import { NavBar } from '../components/NavBar';
import { Session, HistoryItem } from '../common/Session';
import { AccountStore, AccountInfo } from '../common/AccountStore';
import { SmsService } from '../common/SmsService';

@Entry
@Component
struct LoginPage {
  @State mode: string = 'code';
  @State phone: string = '';
  @State code: string = '';
  @State pwd: string = '';
  @State showPwd: boolean = false;
  @State remember: boolean = true;
  @State agreed: boolean = false;
  @State sec: number = 0;
  @State loading: boolean = false;
  @State phoneErr: boolean = false;
  @State codeErr: boolean = false;
  @State pwdErr: boolean = false;
  @State phoneFocus: boolean = false;
  @State codeFocus: boolean = false;
  @State pwdFocus: boolean = false;
  @State history: HistoryItem[] = [];
  @State fromSwitch: boolean = false;
  @State hidePanel: boolean = false;
  private timerId: number = -1;

  aboutToAppear() {
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined)
      return;
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>;
    if (params !== undefined && params !== null && params.switch === '1')
      this.fromSwitch = true;
    Session.getHistory(ctx).then((h: HistoryItem[]) => {
      this.history = h;
    });
    AccountStore.ensureSeed(ctx).then(() => {
      if (this.fromSwitch)
        return;
      return Session.load(ctx).then((phone: string) => {
        if (phone.length > 0)
          this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' });
      });
    });
  }

  aboutToDisappear() {
    if (this.timerId !== -1)
      clearInterval(this.timerId);
  }

  private phonePlain(): string {
    return this.phone.split(' ').join('');
  }

  private phoneOk(): boolean {
    return this.phonePlain().length === 11 && this.phonePlain().charAt(0) === '1';
  }

  private codeOk(): boolean {
    return this.code.length === 6;
  }

  private pwdOk(): boolean {
    return this.pwd.length >= 6;
  }

  private formOk(): boolean {
    if (!this.agreed || !this.phoneOk()) return false;
    return this.mode === 'code' ? this.codeOk() : this.pwdOk();
  }

  private toast(msg: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: msg });
    } catch (err) {
      // 忽略 toast 失败
    }
  }

  private startCountdown(): void {
    this.sec = 60;
    this.timerId = setInterval(() => {
      this.sec -= 1;
      if (this.sec <= 0) {
        clearInterval(this.timerId);
        this.timerId = -1;
        this.sec = 0;
      }
    }, 1000);
  }

  private sendCode(): void {
    if (this.sec > 0 || this.loading)
      return;
    if (!this.phoneOk()) {
      this.phoneErr = true;
      this.toast('请输入正确的 11 位手机号');
      return;
    }
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined)
      return;
    AccountStore.findByPhone(ctx, this.phonePlain()).then((acc: AccountInfo | null) => {
      if (acc === null) {
        this.phoneErr = true;
        this.toast('该手机号未注册，请先注册新账号');
        return;
      }
      const code = SmsService.send(this.phonePlain(), 'login');
      this.startCountdown();
      this.toast(`【演示短信】登录验证码：${code}（5 分钟内有效）`);
    });
  }

  private goIndex(): void {
    this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' });
  }

  private goIndexClearStack(): void {
    this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' }).then(() => {
      this.getUIContext().getRouter().clear();
    });
  }

  private enterIndex(): void {
    if (this.fromSwitch)
      this.goIndexClearStack();
    else
      this.goIndex();
  }

  private finishLogin(ctx: Context, acc: AccountInfo): void {
    Session.addHistory(ctx, acc.phone, acc.nickname).then(() => {
      return Session.save(ctx, acc.phone, this.remember);
    }).then(() => {
      this.loading = false;
      this.toast(`欢迎回来，${acc.nickname}`);
      setTimeout(() => { this.enterIndex(); }, 500);
    });
  }

  private submit(): void {
    if (this.loading)
      return;
    if (!this.agreed) {
      this.toast('请先阅读并勾选用户协议与隐私政策');
      return;
    }
    if (!this.phoneOk()) {
      this.phoneErr = true;
      this.toast('请输入正确的 11 位手机号');
      return;
    }
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined)
      return;

    if (this.mode === 'code') {
      if (!this.codeOk()) {
        this.codeErr = true;
        this.toast('请输入 6 位验证码');
        return;
      }
      if (!SmsService.verify(this.phonePlain(), 'login', this.code)) {
        this.codeErr = true;
        this.toast('验证码错误或已过期');
        return;
      }
      this.loading = true;
      AccountStore.findByPhone(ctx, this.phonePlain()).then((acc: AccountInfo | null) => {
        if (acc === null) {
          this.loading = false;
          this.phoneErr = true;
          this.toast('该手机号未注册，请先注册新账号');
          return;
        }
        this.finishLogin(ctx, acc);
      });
      return;
    }

    // 密码登录
    if (!this.pwdOk()) {
      this.pwdErr = true;
      this.toast('密码至少 6 位');
      return;
    }
    this.loading = true;
    AccountStore.findByPhone(ctx, this.phonePlain()).then((acc: AccountInfo | null) => {
      if (acc === null) {
        this.loading = false;
        this.phoneErr = true;
        this.toast('该手机号未注册，请先注册新账号');
        return;
      }
      return AccountStore.hashPassword(this.phonePlain(), this.pwd).then((hashed: string) => {
        if (hashed !== acc.password) {
          this.loading = false;
          this.pwdErr = true;
          this.toast('密码错误，若忘记可通过绑定手机重置');
          return;
        }
        this.finishLogin(ctx, acc);
      });
    });
  }

  private demoLogin(): void {
    if (this.loading)
      return;
    this.loading = true;
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      this.loading = false;
      return;
    }
    AccountStore.ensureSeed(ctx).then(() => {
      return Session.addHistory(ctx, AccountStore.DEMO_PHONE, '李强');
    }).then(() => {
      return Session.save(ctx, AccountStore.DEMO_PHONE, true);
    }).then(() => {
      this.loading = false;
      this.enterIndex();
    });
  }

  private maskPhone(p: string): string {
    if (p.length !== 11)
      return p;
    return `${p.substring(0, 3)}****${p.substring(7)}`;
  }

  private fieldBorder(focus: boolean, err: boolean): string {
    if (err)
      return Color.critical;
    if (focus)
      return Color.primary;
    return Color.border;
  }

  private fieldBg(focus: boolean): string {
    return focus ? '#F0F9FF' : '#F8FAFC';
  }

  build() {
    Column() {
      // 切换账号入口：顶部返回栏，可返回上一页（原会话仍有效）
      if (this.fromSwitch)
        NavBar({ title: '切换账号', showBack: true })
      Stack() {
      // 背景光斑
      Column()
        .width(220).height(220).borderRadius(110)
        .backgroundColor(Color.primary).opacity(0.10)
        .position({ x: 240, y: -70 })
      Column()
        .width(180).height(180).borderRadius(90)
        .backgroundColor(Color.accent).opacity(0.08)
        .position({ x: -70, y: 170 })
      Column()
        .width(260).height(260).borderRadius(130)
        .backgroundColor(Color.success).opacity(0.07)
        .position({ x: 200, y: 470 })

      Scroll() {
        Column() {
          // ===== 品牌区 =====
          Column() {
            Stack() {
              Column() {
                SymbolGlyph($r('sys.symbol.house_fill'))
                  .fontSize(36)
                  .fontColor(['#FFFFFF'])
              }
              .width(76).height(76).borderRadius(26)
              .justifyContent(FlexAlign.Center)
              .linearGradient(Grad.primary())
              .shadow(Shadow_.pop('rgba(2,132,199,0.38)'))

              Stack() {
                Column()
                  .width(26).height(26).borderRadius(13)
                  .linearGradient(Grad.accent())
                  .shadow(Shadow_.medal('rgba(234,88,12,0.40)'))
                Image($r('app.media.ic_heart'))
                  .width(14).height(14)
              }
              .position({ x: 62, y: 62 })
            }
            .width(90).height(90)

            Text('颐养守护')
              .fontSize(26)
              .fontWeight(FontWeight_.extrabold)
              .fontColor(Color.textPrimary)
              .letterSpacing(2)
              .margin({ top: Space.lg })
            Text('独居老人居家安全监测与应急辅助系统')
              .fontSize(FontSize.caption - 0.5)
              .fontColor(Color.textSecondary)
              .letterSpacing(1)
              .margin({ top: 6 })

            Row() {
              Image($r('app.media.ic_shield'))
                .width(10).height(10)
              Text('鸿蒙分布式安全认证 · 监护人端')
                .fontSize(FontSize.mini - 0.5)
                .fontWeight(FontWeight_.bold)
                .fontColor(Color.primaryDark)
                .margin({ left: 4 })
            }
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor('#FFFFFF')
            .borderRadius(Radius.pill)
            .shadow({ radius: 8, color: 'rgba(2,132,199,0.15)', offsetX: 0, offsetY: 2 })
            .margin({ top: 10 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({ top: Space.xxl + 2 })

          // ===== 表单卡 =====
          Column() {
            // 切换账号面板：从「我的 → 切换账号」进入时展示最近登录
            if (this.fromSwitch && !this.hidePanel && this.history.length > 0) {
              Column() {
                Row() {
                  Text('最近登录')
                    .fontSize(FontSize.caption)
                    .fontWeight(FontWeight_.bold)
                    .fontColor(Color.textSecondary)
                  Blank()
                  Text('使用其他账号')
                    .fontSize(FontSize.caption)
                    .fontWeight(FontWeight_.semibold)
                    .fontColor(Color.primaryDark)
                    .onClick(() => {
                      this.hidePanel = true;
                      this.phone = '';
                    })
                }
                .width('100%')

                Row({ space: 10 }) {
                  ForEach(this.history, (item: HistoryItem) => {
                    Column() {
                      Column() {
                        Text(item.nickname.substring(0, 1))
                          .fontSize(FontSize.body + 2)
                          .fontWeight(FontWeight_.extrabold)
                          .fontColor('#FFFFFF')
                      }
                      .width(40).height(40).borderRadius(14)
                      .justifyContent(FlexAlign.Center)
                      .linearGradient(Grad.primary())
                      Text(item.nickname)
                        .fontSize(FontSize.mini)
                        .fontWeight(FontWeight_.bold)
                        .fontColor(Color.textPrimary)
                        .margin({ top: 4 })
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(this.maskPhone(item.phone))
                        .fontSize(FontSize.mini - 1)
                        .fontColor(Color.textTertiary)
                    }
                    .padding(Space.sm)
                    .backgroundColor('#FFFFFF')
                    .borderRadius(Radius.chip)
                    .shadow(Shadow_.card())
                    .onClick(() => {
                      this.phone = item.phone;
                      this.mode = 'pwd';
                      this.pwd = '';
                      this.code = '';
                      this.phoneErr = false;
                      this.toast(`已选择 ${item.nickname}，请输入密码或获取验证码`);
                    })
                  }, (item: HistoryItem) => item.phone)
                }
                .width('100%')
                .margin({ top: Space.sm })
              }
              .width('100%')
              .padding(Space.md)
              .backgroundColor('#F0F9FF')
              .borderRadius(Radius.button)
              .border({ width: 1, color: Color.primaryLight })
              .margin({ bottom: Space.lg })
            }

            Row() {
              Text('验证码登录')
                .fontSize(FontSize.body)
                .fontWeight(this.mode === 'code' ? FontWeight_.bold : FontWeight_.semibold)
                .fontColor(this.mode === 'code' ? Color.primaryDark : Color.textSecondary)
                .padding({ top: 8, bottom: 8 })
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .borderRadius(9)
                .backgroundColor(this.mode === 'code' ? '#FFFFFF' : 'rgba(0,0,0,0)')
                .shadow(this.mode === 'code'
                  ? { radius: 6, color: 'rgba(15,23,42,0.10)', offsetX: 0, offsetY: 2 }
                  : { radius: 0, color: 'rgba(0,0,0,0)', offsetX: 0, offsetY: 0 })
                .onClick(() => { this.mode = 'code'; })
              Text('密码登录')
                .fontSize(FontSize.body)
                .fontWeight(this.mode === 'pwd' ? FontWeight_.bold : FontWeight_.semibold)
                .fontColor(this.mode === 'pwd' ? Color.primaryDark : Color.textSecondary)
                .padding({ top: 8, bottom: 8 })
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .borderRadius(9)
                .backgroundColor(this.mode === 'pwd' ? '#FFFFFF' : 'rgba(0,0,0,0)')
                .shadow(this.mode === 'pwd'
                  ? { radius: 6, color: 'rgba(15,23,42,0.10)', offsetX: 0, offsetY: 2 }
                  : { radius: 0, color: 'rgba(0,0,0,0)', offsetX: 0, offsetY: 0 })
                .onClick(() => { this.mode = 'pwd'; })
            }
            .width('100%')
            .backgroundColor(Color.track)
            .borderRadius(Radius.chip)
            .padding(3)
            .margin({ bottom: Space.lg })

            // 手机号
            Row() {
              Column() {
                SymbolGlyph($r('sys.symbol.phone_fill'))
                  .fontSize(15)
                  .fontColor([Color.primaryDark])
              }
              .width(30).height(30).borderRadius(10)
              .backgroundColor(Color.primaryLight)
              .justifyContent(FlexAlign.Center)
              .margin({ right: 10 })

              Text('+86')
                .fontSize(FontSize.h3 - 1)
                .fontWeight(FontWeight_.bold)
                .fontColor(Color.textPrimary)
                .padding({ right: 10 })
                .border({ width: { right: 1 }, color: Color.border })
                .margin({ right: 10 })

              TextInput({ placeholder: '请输入手机号', text: this.phone })
                .type(InputType.Number)
                .maxLength(13)
                .fontSize(FontSize.h3 - 1)
                .fontColor(Color.textPrimary)
                .backgroundColor('rgba(0,0,0,0)')
                .padding(0)
                .layoutWeight(1)
                .onChange((v: string) => {
                  this.phone = v;
                  this.phoneErr = false;
                })
                .onFocus(() => { this.phoneFocus = true; })
                .onBlur(() => { this.phoneFocus = false; })
            }
            .width('100%')
            .height(50)
            .padding({ left: Space.md, right: Space.md })
            .backgroundColor(this.fieldBg(this.phoneFocus))
            .borderRadius(Radius.button)
            .border({ width: 1.5, color: this.fieldBorder(this.phoneFocus, this.phoneErr) })
            .margin({ bottom: Space.md })

            // 验证码 / 密码
            if (this.mode === 'code') {
              Row() {
                Column() {
                  Image($r('app.media.ic_shield'))
                    .width(15).height(15)
                }
                .width(30).height(30).borderRadius(10)
                .backgroundColor(Color.primaryLight)
                .justifyContent(FlexAlign.Center)
                .margin({ right: 10 })

                TextInput({ placeholder: '请输入 6 位验证码', text: this.code })
                  .type(InputType.Number)
                  .maxLength(6)
                  .fontSize(FontSize.h3 - 1)
                  .fontColor(Color.textPrimary)
                  .backgroundColor('rgba(0,0,0,0)')
                  .padding(0)
                  .layoutWeight(1)
                  .onChange((v: string) => {
                    this.code = v;
                    this.codeErr = false;
                  })
                  .onFocus(() => { this.codeFocus = true; })
                  .onBlur(() => { this.codeFocus = false; })

                Text(this.sec > 0 ? `${this.sec}s 后重发` : '获取验证码')
                  .fontSize(FontSize.body)
                  .fontWeight(this.sec > 0 ? FontWeight_.semibold : FontWeight_.bold)
                  .fontColor(this.sec > 0 ? Color.textTertiary : Color.primaryDark)
                  .padding({ left: 6 })
                  .onClick(() => { this.sendCode(); })
              }
              .width('100%')
              .height(50)
              .padding({ left: Space.md, right: Space.md })
              .backgroundColor(this.fieldBg(this.codeFocus))
              .borderRadius(Radius.button)
              .border({ width: 1.5, color: this.fieldBorder(this.codeFocus, this.codeErr) })
              .margin({ bottom: Space.md })
            } else {
              Row() {
                Column() {
                  Image($r('app.media.ic_lock'))
                    .width(15).height(15)
                }
                .width(30).height(30).borderRadius(10)
                .backgroundColor(Color.primaryLight)
                .justifyContent(FlexAlign.Center)
                .margin({ right: 10 })

                TextInput({ placeholder: '请输入密码（至少 6 位）', text: this.pwd })
                  .type(this.showPwd ? InputType.Normal : InputType.Password)
                  .maxLength(20)
                  .fontSize(FontSize.h3 - 1)
                  .fontColor(Color.textPrimary)
                  .backgroundColor('rgba(0,0,0,0)')
                  .padding(0)
                  .layoutWeight(1)
                  .onChange((v: string) => {
                    this.pwd = v;
                    this.pwdErr = false;
                  })
                  .onFocus(() => { this.pwdFocus = true; })
                  .onBlur(() => { this.pwdFocus = false; })

                Image(this.showPwd ? $r('app.media.ic_eye') : $r('app.media.ic_eye_off'))
                  .width(18).height(18)
                  .padding({ left: 6 })
                  .onClick(() => { this.showPwd = !this.showPwd; })
              }
              .width('100%')
              .height(50)
              .padding({ left: Space.md, right: Space.md })
              .backgroundColor(this.fieldBg(this.pwdFocus))
              .borderRadius(Radius.button)
              .border({ width: 1.5, color: this.fieldBorder(this.pwdFocus, this.pwdErr) })
              .margin({ bottom: Space.md })

              Row() {
                Row() {
                  Stack() {
                    Column()
                      .width(16).height(16).borderRadius(5)
                      .backgroundColor('#FFFFFF')
                      .border({ width: 1.5, color: this.remember ? 'rgba(0,0,0,0)' : '#CBD5E1' })
                    if (this.remember) {
                      Column()
                        .width(16).height(16).borderRadius(5)
                        .linearGradient(Grad.primary())
                      SymbolGlyph($r('sys.symbol.checkmark'))
                        .fontSize(9)
                        .fontColor(['#FFFFFF'])
                    }
                  }
                  .width(16).height(16)

                  Text('记住登录状态')
                    .fontSize(FontSize.caption - 0.5)
                    .fontColor(Color.textSecondary)
                    .margin({ left: 6 })
                }
                .onClick(() => { this.remember = !this.remember; })

                Blank()
                Text('忘记密码？')
                  .fontSize(FontSize.caption - 0.5)
                  .fontWeight(FontWeight_.semibold)
                  .fontColor(Color.primaryDark)
                  .onClick(() => {
                    this.getUIContext().getRouter().pushUrl({ url: 'pages/ForgotPage' });
                  })
              }
              .width('100%')
              .margin({ bottom: Space.lg - 2 })
            }

            // 登录按钮
            Row() {
              if (this.loading) {
                LoadingProgress()
                  .width(18).height(18)
                  .color('#FFFFFF')
                  .margin({ right: Space.sm })
                Text('登录中…')
                  .fontSize(15)
                  .fontWeight(FontWeight_.bold)
                  .fontColor('#FFFFFF')
                  .letterSpacing(2)
              } else {
                Text('登 录')
                  .fontSize(15)
                  .fontWeight(FontWeight_.bold)
                  .fontColor('#FFFFFF')
                  .letterSpacing(4)
              }
            }
            .width('100%')
            .height(50)
            .justifyContent(FlexAlign.Center)
            .borderRadius(Radius.button)
            .linearGradient(this.formOk() && !this.loading
              ? Grad.primary()
              : { angle: 135, colors: [['#D8E0EA', 0.0], ['#D8E0EA', 1.0]] })
            .shadow(this.formOk() && !this.loading
              ? Shadow_.pop('rgba(2,132,199,0.35)')
              : { radius: 0, color: 'rgba(0,0,0,0)', offsetX: 0, offsetY: 0 })
            .onClick(() => { this.submit(); })

            // 协议
            Row() {
              Stack() {
                Column()
                  .width(14).height(14).borderRadius(4)
                  .backgroundColor('#FFFFFF')
                  .border({ width: 1.5, color: this.agreed ? 'rgba(0,0,0,0)' : '#CBD5E1' })
                if (this.agreed) {
                  Column()
                    .width(14).height(14).borderRadius(4)
                    .linearGradient(Grad.primary())
                  SymbolGlyph($r('sys.symbol.checkmark'))
                    .fontSize(8)
                    .fontColor(['#FFFFFF'])
                }
              }
              .width(14).height(14)
              .margin({ top: 2 })
              .onClick(() => { this.agreed = !this.agreed; })

              Text() {
                Span('我已阅读并同意 ')
                  .fontSize(FontSize.mini)
                  .fontColor(Color.textTertiary)
                Span('《用户协议》')
                  .fontSize(FontSize.mini)
                  .fontColor(Color.primaryDark)
                Span(' 与 ')
                  .fontSize(FontSize.mini)
                  .fontColor(Color.textTertiary)
                Span('《隐私政策》')
                  .fontSize(FontSize.mini)
                  .fontColor(Color.primaryDark)
                Span('，未注册手机号验证后将自动创建监护人账号')
                  .fontSize(FontSize.mini)
                  .fontColor(Color.textTertiary)
              }
              .layoutWeight(1)
              .margin({ left: 7 })
              .lineHeight(16)
              .onClick(() => { this.agreed = !this.agreed; })
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
            .margin({ top: Space.lg - 2 })

            // 注册入口
            Row() {
              Text('新用户？')
                .fontSize(FontSize.caption)
                .fontColor(Color.textTertiary)
              Text('立即注册并绑定手机号')
                .fontSize(FontSize.caption)
                .fontWeight(FontWeight_.bold)
                .fontColor(Color.primaryDark)
                .margin({ left: 4 })
                .onClick(() => {
                  this.getUIContext().getRouter().pushUrl({ url: 'pages/RegisterPage' });
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: Space.md })
          }
          .width('100%')
          .padding(Space.lg)
          .backgroundColor(Color.card)
          .borderRadius(22)
          .shadow({ radius: 30, color: 'rgba(15,23,42,0.08)', offsetX: 0, offsetY: 10 })
          .margin({ top: Space.xxl })

          // 评审演示入口
          Row() {
            SymbolGlyph($r('sys.symbol.star_fill'))
              .fontSize(15)
              .fontColor([Color.accentDark])
            Text('评审演示：')
              .fontSize(FontSize.body + 0.5)
              .fontWeight(FontWeight_.semibold)
              .fontColor(Color.textSecondary)
              .margin({ left: 7 })
            Text('一键体验监护人「李强」账号')
              .fontSize(FontSize.body + 0.5)
              .fontWeight(FontWeight_.bold)
              .fontColor(Color.accentDark)
          }
          .width('100%')
          .height(46)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#FFFFFF')
          .borderRadius(Radius.button)
          .border({ width: 1.5, color: '#94A3B8', style: BorderStyle.Dashed })
          .margin({ top: Space.lg })
          .onClick(() => { this.demoLogin(); })

          Text('颐养守护 v1.0.0\n第三届河南省信息技术应用创新大赛 · 赛题四')
            .fontSize(FontSize.mini - 0.5)
            .fontColor(Color.textTertiary)
            .textAlign(TextAlign.Center)
            .lineHeight(18)
            .margin({ top: Space.lg + 2, bottom: Space.xl })
        }
        .width('100%')
        .padding({ left: Space.xxl, right: Space.xxl })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.bg)
    .linearGradient(Grad.headWash())
  }
}
