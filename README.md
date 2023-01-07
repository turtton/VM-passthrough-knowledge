# VM Passthrough Knowledge 

このリポジトリは自身のVM環境の知見を雑多にまとめたもの
いろいろ試行錯誤した結果なんかうまくいった環境なので色々適当。完全に自分用

### 環境

- OS: ArchLinux(linux-kernel)
- CPU: Ryzen5 3600
- GPU: RTX2060

### 状態

:white_check_mark: Single GPU Passthrough
:white_check_mark: CPU timestamp check(rdtsc)
:no_entry: CPU timestamp forcing VM exit check(rdtsc)

情報は[pafish](https://github.com/a0rtega/pafish)より

簡単に言うと大体のゲームとかをネイティブに近い状態で動かすことができるが、アンチチートにはバレる。
BEにはバレた(たるこふで検証)、EACには見逃がされた(ふぉるがいずで検証)

> BEのバレ方は二段階あって、まずレジストリのマザボ情報とかで先にバレてマッチング中に蹴りだされる。
> それを偽装しても次はrdtscでバレて試合中に蹴りだされる(ような雰囲気がした)

[WCharacter/RDTSC-KVM-Handler](WCharacter/RDTSC-KVM-Handler)とか試せばいけるんだろうか(未検証)

他にもQuest2はUSBを普通にハードウェアパススルーで渡すだけだと無理だったりする
※PCIスロットの拡張USBをPCIパススルーするといけるとかなんとか(redditで見た気がする)

# 参考になったやつ

- [ArchWiki](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
  とりあえずこれ見ろ。ちなみに日本語と英語で若干情報が違うから両方見ろ
- [joeknock90/Single-GPU-Passthrough](joeknock90/Single-GPU-Passthrough)
  SingleGPUのパススルー方法の知見は全てここから

# やったこと

なるべく全てまとめてますが、取り組んでた頃からかなり経ってるので色々情報抜けてると思う

使ってるアプリケーションは`libvirt`/`qemu`/`virt-manager`あたり。他にも必要なものがあるかも

## VMを作る前に

### KVMの設定(AMD向け)

これなんだっけ。多分kvmのCPUの設定？まあおまじない(TODO: ソース見つけたらのせる)

`/etc/modprobe.d/kvm.conf`

```
options kvm_amd nested=1
options kvm ignore_msrs=1
```

### KVMの早期ロード

mkinitcpioで書くのはkvmだけでよい(SingleGPUの場合後のモジュールは後からロードする)

`/etc/mkinitcpio.conf`

```
MODULES=(KVM usbmon)
```

`usbmon`はなんか自分のやつに書いてあったから書いとく。いらないかも
あとこれ設定したら`mkinitcpio -P`でinitramfsを再生成するのをお忘れなく

### qemuのhookの追加

[ソース](https://passthroughpo.st/simple-per-vm-libvirt-hooks-with-the-vfio-tools-hook-helper/)
VMが起動/終了する度にGPUの切り替えをするのでこれが必要
詳しいことはソースを見てくれ

大体はこれで解決
```
sudo mkdir -p /etc/libvirt/hooks
sudo wget 'https://raw.githubusercontent.com/PassthroughPOST/VFIO-Tools/master/libvirt_hooks/qemu' \
     -O /etc/libvirt/hooks/qemu
sudo chmod +x /etc/libvirt/hooks/qemu
sudo service libvirtd restart
```

一応ファイルは[ここ](hooks/qemu)にも置いてある

## VMを作るとき

作ったの数ヶ月前だし正直覚えてない。この辺は改めて調べたほうがよさそう

とりあえずWin10にしておくことをおすすめする。11はTPM周りのこともあるので、EACとかにもバレやすくなると思う。[WindowsAME](https://ameliorated.info)が理想なんだけど、更新止まったし今は微妙かも

あと60GB以下はそれだけでVMと怪しまれることがあるので最低でも120GBは欲しい

基本的にはVirtualMachineManagerのダイアログ通りに進めれば良いが、インストール前に設定を変更みたいなやつにチェックを入れて、CPUのコア設定を変える。ソケット1/コア6/スレッド2とかだったはず

そのままOSインストールして終ったらOK

## VMが出来たら

とりあえずSpice系のモジュールを削除して、キーボードとかの必要なUSBを全て追加、あとGPUもPCIのやつから追加する

`/etc/libvirt/hooks/qemu.d/{VM名}/`の中に必要なhookを配置する
詳細は[ここ](https://github.com/joeknock90/Single-GPU-Passthrough#libvirt-hook-scripts) 一応使ってたファイルは[hooks](hooks)フォルダ内にあるので参考に

ここでもっかいVM設定を弄っておく。xmlの中身もVMMからいじれる(設定変えたらいけるはず)
ここはマジで試行錯誤しすぎて記憶ないです(CPUまわりを色々変えてたはず)。
[前のファイル](qemu/GamingWin10R.xml)置いてあるから比較していろいろやってくれ

