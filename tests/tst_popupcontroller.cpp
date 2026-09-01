#include <QtTest>

#include "PopupController.h"

class PopupControllerTest final : public QObject
{
    Q_OBJECT

private slots:
    void startsClosed();
    void openEmitsOnce();
    void toggleKeepsOnlyOnePopupOpen();
    void closeIsIdempotent();
};

void PopupControllerTest::startsClosed()
{
    PopupController controller;

    QVERIFY(!controller.anyOpen());
    QVERIFY(controller.active().isEmpty());
}

void PopupControllerTest::openEmitsOnce()
{
    PopupController controller;
    QSignalSpy activeSpy(&controller, &PopupController::activeChanged);
    QSignalSpy openedSpy(&controller, &PopupController::opened);

    controller.open(QStringLiteral("wifi"));

    QCOMPARE(controller.active(), QStringLiteral("wifi"));
    QVERIFY(controller.anyOpen());
    QCOMPARE(activeSpy.count(), 1);
    QCOMPARE(openedSpy.count(), 1);
    QCOMPARE(openedSpy.takeFirst().at(0).toString(), QStringLiteral("wifi"));

    // Mở lại cùng popup không được phát tín hiệu thừa hoặc khởi động lại polling.
    controller.open(QStringLiteral("wifi"));
    QCOMPARE(activeSpy.count(), 1);
    QCOMPARE(openedSpy.count(), 0);
}

void PopupControllerTest::toggleKeepsOnlyOnePopupOpen()
{
    PopupController controller;
    QSignalSpy openedSpy(&controller, &PopupController::opened);

    controller.toggle(QStringLiteral("wifi"));
    QCOMPARE(controller.active(), QStringLiteral("wifi"));

    controller.toggle(QStringLiteral("volume"));
    QCOMPARE(controller.active(), QStringLiteral("volume"));

    // Toggle popup đang mở phải đóng tất cả.
    controller.toggle(QStringLiteral("volume"));
    QVERIFY(controller.active().isEmpty());
    QVERIFY(!controller.anyOpen());

    QCOMPARE(openedSpy.count(), 3);
    QCOMPARE(openedSpy.at(0).at(0).toString(), QStringLiteral("wifi"));
    QCOMPARE(openedSpy.at(1).at(0).toString(), QStringLiteral("volume"));
    QCOMPARE(openedSpy.at(2).at(0).toString(), QString());
}

void PopupControllerTest::closeIsIdempotent()
{
    PopupController controller;
    QSignalSpy activeSpy(&controller, &PopupController::activeChanged);

    controller.close();
    QCOMPARE(activeSpy.count(), 0);

    controller.open(QStringLiteral("calendar"));
    controller.close();
    QCOMPARE(activeSpy.count(), 2);
    QVERIFY(!controller.anyOpen());

    controller.close();
    QCOMPARE(activeSpy.count(), 2);
}

QTEST_APPLESS_MAIN(PopupControllerTest)
#include "tst_popupcontroller.moc"
