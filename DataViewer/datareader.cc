#include "datareader.hh"
#include "jsonparser.hh"
#include <QTimer>
#include <QDebug>
#include <QEventLoop>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QList>
#include <QPair>
#include <QDateTime>

DataReader::DataReader(QObject *parent) : QObject(parent)
{

    // Mapping arrays for service and meters names / ids
    service_names["outside_temperature"] = "Temperature";    
    service_names["energy_consumption"] = "Energy consumption";
    service_names["solar_panels"] = "Solar panels";
    service_names["cooling_power_usage"] = "Cooling power usage";
    
    meter_names["ut01_te00"] = "Temperature 1";
    meter_names["leeeroof_hmp155_t"] = "Temperature 2";
    
    meter_names["pm3255_hkasjk0101_eptot_imp"] = "Energy consumption";
    
    meter_names["pv01_inverter01_totalyield"] = "Solar panel group 1";
    meter_names["pv01_inverter02_totalyield"] = "Solar panel group 2";
    meter_names["pv01_inverter03_totalyield"] = "Solar panel group 3";
    meter_names["pv01_inverter04_totalyield"] = "Solar panel group 4";
    meter_names["lv3_solarpvplant_ep_plus"] = "All solar panels";
    
    meter_names["lv3_ventilation_ep_plus"] = "Ventilation machine rooms";
    meter_names["lv3_watercooling01_ep_plus"] = "Water cooling machine 1";
    meter_names["lv3_watercooling02_ep_plus"] = "Water cooling machine 2";

    service_to_meter["ut01_te00"] = "outside_temperature";
    service_to_meter["leeeroof_hmp155_t"] = "outside_temperature";

    service_to_meter["pm3255_hkasjk0101_eptot_imp"] = "energy_consumption";

    service_to_meter["pv01_inverter01_totalyield"] = "solar_panels";
    service_to_meter["pv01_inverter02_totalyield"] = "solar_panels";
    service_to_meter["pv01_inverter03_totalyield"] = "solar_panels";
    service_to_meter["pv01_inverter04_totalyield"] = "solar_panels";
    service_to_meter["lv3_solarpvplant_ep_plus"] = "solar_panels";

    service_to_meter["lv3_ventilation_ep_plus"] = "cooling_power_usage";
    service_to_meter["lv3_watercooling01_ep_plus"] = "cooling_power_usage";
    service_to_meter["lv3_watercooling02_ep_plus"] = "cooling_power_usage";
    
       
    parser = new JSONParser();

    // Send new values every 10 seconds
    timer = new QTimer(this);
    connect(timer, SIGNAL(timeout()), this, SLOT(sendCurrentValues()));
    timer->start(10000);
}

// Hakee datan annetulta päivältä halutulle mittarille
QVariantList DataReader::getDataFromDay(QString data_type, QString meter_id, QDate day)
{
    QVariantList data;
    QNetworkAccessManager mgr;

    // Muokataan päivät stringeiksi ja alustetaan arvot
    QString first = day.toString("yyyy-MM-dd");

    QString service;
    service = data_type;

    int offset = 0;
    int limit = 100;
    bool values_check = true;
    QDate border_date = QDate::fromString("20181008", "yyyyMMdd");

    // Muutetaan näytteen ottoväliä, kun data lähde siirtyi 10sekunnista 15min näytetaajuuteen
    if ( day.operator <=(border_date) ) {
        limit = 1;
    }
    while (values_check) {
        QString hOffset = QString::number(offset);
        QString hLimit = QString::number(limit);
        QUrl url = QUrl(QString("https://test.ain.rd.tut.fi:8666/fiware/STH/v1/contextEntities/type/Measurement/id/"+meter_id+
                                "/attributes/measuredValue?hLimit="+hLimit+"&hOffset="+hOffset+"&dateFrom="
                                +first+"T00:00:00.000Z&dateTo="+first+"T23:59:59.999Z"));

        QIODevice *ret = getHttpDataReader(mgr, url, service, "/");

        if ( ret == nullptr ) {
            ret_val = false;
            data.clear();
            return data;
        }
        QByteArray res = ret->readAll();

        data = parser->getHistory(res);
        //qDebug() << "parserilta:" << data;
        //qDebug() << data_from_meter.size();
        if ( data.size() < limit ) {
            values_check = false;
        }
        // Vanhan tietorakenteen mukainen muokkaus
        /*for ( QVariantMap::const_iterator iter = data_from_meter.begin(); iter != data_from_meter.end(); ++iter ) {
            QDateTime timestamp = QDateTime::fromString(iter.key(),"yyyy-MM-ddTHH:mm:ss.zzzZ");
            bool ok = false;
            double value = iter.value().toDouble(&ok);
            data.append(qMakePair(timestamp, value));
        } */

        offset += 100;
    }
    qDebug() << day << "arvoja:" << data.length();
    //qDebug() << data;
    return data;
}

// Hakee ja palauttaa datan annetulta aikaväliltä. Muuntaa kumulatiivisen datan hetkelliseksi
QVariantList DataReader::getData(QString data_type, QString meter_id, QDate start, QDate end)
{
    //qDebug() << "Getting data " << data_type << meter_id << start << end;

    //QList<QPair<QDateTime, double>> data;
    //QList<QPair<QDateTime, double>> day_data;
    QVariantList data;
    QVariantList day_data;
    
    DataReader reader;
    QDate day = start;
    while ( day.operator <=(end) ) {
        day_data = reader.getDataFromDay(data_type, meter_id, day);

        if (!ret_val){
            data.clear();
            return data;
        }

        data.append(day_data);
        day = day.addDays(1);
    }

    // Lasketaan hetkelliset arvot cumulatiivisesta
    if ( data_type != "outside_temperature" ) {
        int j = 0;
        //QList<QPair<QDateTime, double>> data_temporary;
        QVariantList data_temporary;
        while ( j < data.length() ) {
            if ( j == data.length() - 1 ) {
                // hae seuraava päivältä tai poista lämpötiloista yksi
            } else {
                // Määritetään aikaleimojen ja arvojen erot
                qint64 timediffirence = data[j].toMap().value("timestamp").toDateTime().secsTo(data[j+1].toMap().value("timestamp").toDateTime());
                double valuediffirence = data[j+1].toMap().value("value").toDouble() - data[j].toMap().value("value").toDouble();

                // Korjataan lukema kwh aikavälin pituudella (jos esim. puuttuvia mittauksia)
                valuediffirence = valuediffirence*3600/timediffirence;

                // Muodostetaan uusi hetkellinen arvo
                QVariantMap data_pair;
                const QString timestamp = "timestamp";
                const QString value = "value";
                data_pair.insert(timestamp, data[j].toMap().value("timestamp").toDateTime().addSecs(timediffirence/2).toString("yyyy-MM-ddTHH:mm:ss.zzzZ"));
                data_pair.insert(value, QVariant(valuediffirence).toString());
                data_temporary.append(data_pair);
            }

            j += 1;
        }
        // Poistetaan kumulatiiviset ja palautetaan hetkelliset
        //qDebug() << data;
        data.clear();
        data.append(data_temporary);
        //for ( auto pair : data_temporary ) {
            //data.append(qMakePair(pair.first, pair.second));
        //}
    } else {
        // Poistetaan vika lämpötila, jotta lkm vastaa muita mittareita vertailua varten (mikäli on)
        if ( data.length() > 0 ) {
            data.pop_back();
        }
    }

    qDebug() << "Total:" << data.length();
    //qDebug() << data;
    return data;
}

QVariantList DataReader::getServices()
{
    QVariantList services;
    for(auto key : service_names.keys())
    {
          services << key;
    }
    return services;
}

// Returns list of meter_ids for given service
QVariantList DataReader::getMeters(QString service)
{
    // Check if meter ids have already been fetched from Orion Context Broker
    if (!meters.contains(service)){
        return getMetersFromOCB(service);
    }
    else {
        return meters[service];
    }
}

// Get data from STH-Comet and OCB
QIODevice* DataReader::getHttpDataReader(QNetworkAccessManager& mgr, QUrl url, QString service, QString service_path) {
    QEventLoop eventLoop;
    QObject::connect(&mgr, SIGNAL(finished(QNetworkReply*)),&eventLoop, SLOT(quit()));
    QNetworkRequest req(url);
    req.setRawHeader("FIWARE-Service", service.toUtf8());

    if (!service.isEmpty()){
        req.setRawHeader("Fiware-Servicepath", service_path.toUtf8());
    }

    QNetworkReply *reply = mgr.get(req);

    eventLoop.exec();

    if (reply->error() == QNetworkReply::NoError) {
        return reply;
    }
    else {
        qDebug() << "Network error";
        return nullptr;
    }
}

// Get list of meter_ids for given service from OCB
QVariantList DataReader::getMetersFromOCB(QString service)
{
    QNetworkAccessManager mgr;
    QUrl url = QUrl(QString("https://test.ain.rd.tut.fi:1026/fiware/v2/entities"));
    QIODevice *ret = getHttpDataReader(mgr, url, service, "");
    if (ret == nullptr){
        qDebug() << "Getting meters failed";
        return QVariantList();
    }

    QByteArray res = ret->readAll();

    QVariantList meters;
    QList<QPair<QString, QString>> meters_for_service = parser->getMeters(res);
    QList<QPair<QString, QString>>::iterator it = meters_for_service.begin();

    while (it != meters_for_service.end()){
        meters.append((*it).first);
        units.insert((*it).first, (*it).second);
        it++;
    }

    return meters;
}

// Return latest value for given service and meter_id
double DataReader::getLatestValue(QString service, QString meter_id)
{
    QNetworkAccessManager mgr;
    QUrl url = QUrl(QString("https://test.ain.rd.tut.fi:1026/fiware/v2/entities"));
    QIODevice *ret = getHttpDataReader(mgr, url, getServiceId(service), "");
    if (ret != nullptr) {
        QByteArray res = ret->readAll();
        qDebug()<<res;
        QDateTime timestamp;
        QString unit;
        double value;
        ret_val = parser->getCurrentValue(res, meter_id, timestamp, value, unit);
        return value;

    }
    else {
        qDebug() << "Could not get data from service: " << service;
        ret_val = false;
        return 0;
    }
}

QString DataReader::getServiceId(QString service_name)
{
    return service_names.key(service_name);
}

QString DataReader::getServiceName(QString service_id)
{
    return service_names.value(service_id);
}

QString DataReader::getMeterId(QString meter_name)
{
    return meter_names.key(meter_name);
}

QString DataReader::getMeterName(QString meter_id)
{
    return meter_names.value(meter_id);
}

QString DataReader::getServiceToMeter(QString meter_id)
{
    return service_to_meter.value(meter_id);
}

QString DataReader::getUnit(QString meter_id)
{
    return units.value(meter_id, "");
}

QDateTime DataReader::getTimeStamp()
{
    QDateTime dt = QDateTime::currentDateTime();
    qDebug() << dt;
    return dt;
}

QDateTime DataReader::variantToDateTime(QVariant date)
{
    QDateTime newDate = date.toDateTime();
    return newDate;

}

QDateTime DataReader::getMinDate() {

    QDateTime min = QDateTime::fromString("01.06.2018", "dd.mm.yyyy");

    return min;
}

bool DataReader::getLatestRetVal()
{
    return ret_val;
}

// Send valueChanged -signal for all meters on all services
void DataReader::sendCurrentValues(){
    QVariantList services = getServices();

    for (QVariantList::iterator i = services.begin(); i != services.end(); i++) {
        QString service = (*i).toString();
        QNetworkAccessManager mgr;
        QUrl url = QUrl(QString("https://test.ain.rd.tut.fi:1026/fiware/v2/entities"));
        QIODevice *ret = getHttpDataReader(mgr, url, service, "");

        if (ret != nullptr) {
            QByteArray res = ret->readAll();

            QVariantList meters = getMeters(service);
            for (QVariantList::iterator j = meters.begin(); j != meters.end(); j++) {
                QString meter_id = (*j).toString();
                double value;
                QDateTime timestamp;
                QString unit;
                ret_val = parser->getCurrentValue(res, meter_id, timestamp, value, unit);
                emit valueChanged(service, meter_id, timestamp.toString(), value, unit);
            }
        }
        else {
            qDebug() << "Could not get data from service: " << service;
            ret_val = false;
        }
    }
}




