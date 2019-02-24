#include "usermanager.hh"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDateTime>
#include <QDebug>
#include <QApplication>
#include <datareader.hh>
#include "dataanalyzer.hh"


int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QApplication app(argc, argv);

    // Register C++ classes to be used in QML
    qmlRegisterType<DataReader>("DataViewer.datareader", 1, 0, "DataReader");
    qmlRegisterType<UserManager>("DataViewer.usermanager", 1, 0, "UserManager");
    qmlRegisterType<DataAnalyzer>("DataViewer.dataanalyzer", 1, 0, "DataAnalyzer");

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;


    return app.exec();
}
