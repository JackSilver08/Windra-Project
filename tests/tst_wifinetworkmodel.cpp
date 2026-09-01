#include <QtTest>

#include "WifiNetworkModel.h"

namespace {
WifiNetwork network(const QString &ssid,
                    int strength,
                    const QString &path,
                    bool active = false,
                    const QString &security = QStringLiteral("open"),
                    bool secured = false,
                    bool known = false)
{
    WifiNetwork value;
    value.ssid = ssid;
    value.path = path;
    value.security = security;
    value.strength = strength;
    value.secured = secured;
    value.known = known;
    value.active = active;
    return value;
}
}

class WifiNetworkModelTest final : public QObject
{
    Q_OBJECT

private slots:
    void activeNetworkIsSeparatedFromAvailableList();
    void filteringIsTrimmedAndCaseInsensitive();
    void signalBarsFollowStrengthThresholds();
    void accessPointPathRefreshIsNotIgnored();
    void unchangedFilterDoesNotEmitAgain();
};

void WifiNetworkModelTest::activeNetworkIsSeparatedFromAvailableList()
{
    WifiNetworkModel model;
    model.setNetworks({
        network(QStringLiteral("Home"), 88, QStringLiteral("/ap/home"), true,
                QStringLiteral("psk"), true, true),
        network(QStringLiteral("FPT Telecom"), 63, QStringLiteral("/ap/fpt")),
        network(QStringLiteral("Coffee House"), 41, QStringLiteral("/ap/coffee")),
    });

    QCOMPARE(model.totalCount(), 3);
    QCOMPARE(model.rowCount(), 2);
    QCOMPARE(model.activeNetwork().ssid, QStringLiteral("Home"));
    QCOMPARE(model.activeNetwork().path, QStringLiteral("/ap/home"));

    QCOMPARE(model.data(model.index(0, 0), WifiNetworkModel::SsidRole).toString(),
             QStringLiteral("FPT Telecom"));
}

void WifiNetworkModelTest::filteringIsTrimmedAndCaseInsensitive()
{
    WifiNetworkModel model;
    model.setNetworks({
        network(QStringLiteral("FPT Telecom"), 65, QStringLiteral("/ap/1")),
        network(QStringLiteral("Office Mesh"), 72, QStringLiteral("/ap/2")),
        network(QStringLiteral("Coffee House"), 34, QStringLiteral("/ap/3")),
    });

    model.setFilter(QStringLiteral("  office  "));
    QCOMPARE(model.rowCount(), 1);
    QCOMPARE(model.data(model.index(0, 0), WifiNetworkModel::SsidRole).toString(),
             QStringLiteral("Office Mesh"));

    model.setFilter(QStringLiteral("FPT"));
    QCOMPARE(model.rowCount(), 1);
    QCOMPARE(model.data(model.index(0, 0), WifiNetworkModel::SsidRole).toString(),
             QStringLiteral("FPT Telecom"));

    model.setFilter(QString());
    QCOMPARE(model.rowCount(), 3);
}

void WifiNetworkModelTest::signalBarsFollowStrengthThresholds()
{
    WifiNetworkModel model;
    model.setNetworks({
        network(QStringLiteral("zero"), 0, QStringLiteral("/0")),
        network(QStringLiteral("one"), 1, QStringLiteral("/1")),
        network(QStringLiteral("two"), 25, QStringLiteral("/2")),
        network(QStringLiteral("three"), 50, QStringLiteral("/3")),
        network(QStringLiteral("four"), 75, QStringLiteral("/4")),
    });

    const QList<int> expected{0, 1, 2, 3, 4};
    QCOMPARE(model.rowCount(), expected.size());

    for (int row = 0; row < expected.size(); ++row) {
        QCOMPARE(model.data(model.index(row, 0), WifiNetworkModel::BarsRole).toInt(),
                 expected.at(row));
    }
}

void WifiNetworkModelTest::accessPointPathRefreshIsNotIgnored()
{
    WifiNetworkModel model;

    model.setNetworks({
        network(QStringLiteral("Home"), 80, QStringLiteral("/org/freedesktop/NM/AP/1"), true,
                QStringLiteral("psk"), true, true),
    });
    QCOMPARE(model.activeNetwork().path,
             QStringLiteral("/org/freedesktop/NM/AP/1"));

    // NetworkManager có thể cấp object path mới sau rescan trong khi các thuộc tính
    // người dùng nhìn thấy giữ nguyên. Model phải nhận ra thay đổi này.
    model.setNetworks({
        network(QStringLiteral("Home"), 80, QStringLiteral("/org/freedesktop/NM/AP/9"), true,
                QStringLiteral("psk"), true, true),
    });
    QCOMPARE(model.activeNetwork().path,
             QStringLiteral("/org/freedesktop/NM/AP/9"));
}

void WifiNetworkModelTest::unchangedFilterDoesNotEmitAgain()
{
    WifiNetworkModel model;
    model.setNetworks({network(QStringLiteral("Windra Lab"), 70, QStringLiteral("/ap/lab"))});

    QSignalSpy filterSpy(&model, &WifiNetworkModel::filterChanged);
    model.setFilter(QStringLiteral("windra"));
    QCOMPARE(filterSpy.count(), 1);

    model.setFilter(QStringLiteral("windra"));
    QCOMPARE(filterSpy.count(), 1);
}

QTEST_APPLESS_MAIN(WifiNetworkModelTest)
#include "tst_wifinetworkmodel.moc"
