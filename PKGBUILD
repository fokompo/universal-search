pkgname=universal-search
pkgver=1.0.0
pkgrel=2
pkgdesc="Search Google, YouTube, GitHub, Wikipedia and more from the terminal"
url='https://github.com/fokompo/universal-search'
arch=('any')
license=('MIT')
depends=('bash' 'xdg-utils')
source=('search')
sha256sums=('SKIP')

package() {
    install -Dm755 "$srcdir/search" "$pkgdir/usr/bin/search"

    cd "$pkgdir/usr/bin"
    ln -s search s
    ln -s search S
    ln -s search Search
}
