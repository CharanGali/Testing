################################################################################
# 概要
# ==========
# Application Gatewayのバックアップファイルにパッチを当てて
# リストア可能なテンプレートを生成するためのjqコマンドフィルタスクリプト
# (エクスポート時に情報が消失するのでリストア時に再注入が必要)
#
# パラメータ
# ==========
# * $subscCode: サブスクリプションコード
#    e.g.) gcspre
#
# 参考
# ==========
# * jq Manual
#   * https://stedolan.github.io/jq/manual/
# * jqを使用して複数のフィールド値を検索して置換する方法
#   * https://unix.stackexchange.com/questions/476536/how-to-find-and-replace-multiple-field-values-using-jq
# * jqにて複数をパラメータを区分けする時、セミコロン(;)を識別子として使います
#
################################################################################

# SSL証明書用のパラメータ情報(パラメータ名の宣言箇所)を追加
#
# * .parameters 配下にフィールドを追加する形でパッチします
# * 複数の対象を同じJSON objectで一括置換します
# * 新規構築時と同様、type: securestring 形式の引数です(実体はKey Vaultに定義)
def prepare_parameter_definition(target):
  target |= { type: "securestring" };

# SSL証明書用のパラメータ情報(Key VaultのIDやパスワード)を追加
#
# * .resources.[].properties.sslCertificates.[].propertyにパッチします
# * .resources.[].properties.sslCertificates.[]が複数あるので、
#   nameフィールドでパッチ対象を絞り込んでから行います
# * 対象の絞り込みには `Recursive Descent: ..` を使い、
#   見つかったフィールドをJSON objectで置換します
# * ?を付与して対象が見つからなくてもエラーにならないように考慮してあります
def fill_ssl_certificates_properties(search_name; fill_properties):
  (
    ..|.resources?|.[]?|.properties?|.sslCertificates?|.[]?|
      select(.name? == search_name)
  ).properties |= fill_properties;

########################################
# 定義済み関数を呼び出してフィルタを実行

## 変数宣言部分を挿入
prepare_parameter_definition(
  (
    .parameters.agwTlsCertificate,
    .parameters.agwTlsPassword,
    .parameters.aitriosAgwTlsCertificate,
    .parameters.aitriosAgwTlsPassword
  )) |

## sssiotpfs.com 用のSSL証明書プロパティを挿入
fill_ssl_certificates_properties(
  ## naming-rule: "${SUBSCRIPTION_CODE}SslCert"
  $subscCode + "SslCert";
  {
    data: "[parameters('agwTlsCertificate')]",
    password: "[parameters('agwTlsPassword')]"
  }) |

## aitrios.sony-semicon.co.jp 用のSSL証明書プロパティを挿入
fill_ssl_certificates_properties(
  ## naming-rule: "cert-${SUBSCRIPTION_CODE}-aitrios"
  "cert-" + $subscCode + "-aitrios";
  {
    data: "[parameters('aitriosAgwTlsCertificate')]",
    password: "[parameters('aitriosAgwTlsPassword')]"
  })
