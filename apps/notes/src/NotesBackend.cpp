#include "NotesBackend.h"
#include <QFile>
#include <QTextStream>
QString NotesBackend::load(const QUrl &url) { QFile f(url.toLocalFile()); if(!f.open(QIODevice::ReadOnly|QIODevice::Text)) return {}; QTextStream s(&f); return s.readAll(); }
bool NotesBackend::save(const QUrl &url, const QString &text) { QFile f(url.toLocalFile()); if(!f.open(QIODevice::WriteOnly|QIODevice::Text|QIODevice::Truncate)) return false; QTextStream s(&f); s << text; return true; }
