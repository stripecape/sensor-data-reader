#ifndef DATAREADER_HH
#define DATAREADER_HH

#include "jsonparser.hh"

#include <QObject>
#include <QString>
#include <QTimer>
#include <QPair>
#include <QList>
#include <QDateTime>
#include <QIODevice>
#include <QNetworkAccessManager>
#include <QVariantList>
#include <QMap>



class DataReader : public QObject
{
    Q_OBJECT
public:
    
    
    explicit DataReader(QObject *parent = nullptr);
    Q_INVOKABLE QVariantList getDataFromDay(QString data_type, QString meter_id, QDate day);
    Q_INVOKABLE QVariantList getData(QString data_type, QString meter_id, QDate start, QDate end);
    Q_INVOKABLE QVariantList getServices();
    Q_INVOKABLE QVariantList getMeters(QString service);
    QVariantList getMetersFromOCB(QString service);
    Q_INVOKABLE double getLatestValue(QString service, QString meter_id);

    Q_INVOKABLE QString getServiceId(QString service_name);
    Q_INVOKABLE QString getServiceName(QString service_id);
    Q_INVOKABLE QString getMeterId(QString meter_name);
    Q_INVOKABLE QString getMeterName(QString meter_id);
    Q_INVOKABLE QString getServiceToMeter(QString meter_id);
    Q_INVOKABLE QString getUnit(QString meter_id);

    Q_INVOKABLE QDateTime getTimeStamp();
    Q_INVOKABLE QDateTime variantToDateTime(QVariant date);
    Q_INVOKABLE QDateTime getMinDate();

    Q_INVOKABLE bool getLatestRetVal();



    QIODevice* getHttpDataReader(QNetworkAccessManager& mgr, QUrl url, QString service, QString service_path = "");
signals:
    void valueChanged(QString data_type, QString meter_id, QString timestamp, double value, QString unit);

public slots:
    void sendCurrentValues();

private:
    QTimer *timer;
    JSONParser *parser;
    bool ret_val = true;
    QMap<QString, QVariantList> meters;
    QMap<QString, QString> units;
    QMap<QString, QString> service_names;
    QMap<QString, QString> meter_names; 
    QMap<QString, QString> service_to_meter;
};

#endif // DATAREADER_HH
