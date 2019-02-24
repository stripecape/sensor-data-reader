#include "jsonparser.hh"
#include <QTextStream>
#include <QJsonArray>
#include <iostream>
#include <QJsonObject>
#include <QDebug>
#include <QJsonValue>

JSONParser::JSONParser()
{

}

// Parses meters from latest value
QList<QPair<QString, QString>> JSONParser::getMeters(QByteArray json_bytes) {

    QString meter;
    QString unit;
    QJsonValue idJsonValue;
    QJsonValue unitObj;
    QList<QPair<QString, QString>> meterList;
    auto json_doc = QJsonDocument::fromJson(json_bytes);

    if (json_doc.isNull()) {
        return meterList;
    }

    if (json_doc.isArray()) {
        QJsonArray jsonArray = json_doc.array();
        QJsonArray::iterator j;

        for (j = jsonArray.begin(); j != jsonArray.end(); ++j) {
            QJsonValue jsonValue = *j;
            QJsonObject item = jsonValue.toObject();

            idJsonValue = parseObject(item, "id");
            meter = idJsonValue.toString();

            unitObj = parseObject(item, "unit");
            unit = parseObject(unitObj.toObject(), "value").toString();

            QPair<QString, QString> pair;
            pair.first = meter;
            pair.second = unit;

            meterList.append(pair);
        }
    }

    return meterList;

}


bool JSONParser::getCurrentValue(QByteArray json_bytes, QString meter_id, QDateTime &timestamp, double &value, QString &unit)
{
    QJsonValue variant;

    auto json_doc = QJsonDocument::fromJson(json_bytes);

    if (json_doc.isNull()) {

        return false;
    }

    if (json_doc.isArray()) {
        QJsonArray jsonArray = json_doc.array();
        QJsonArray::iterator i;

        for (i = jsonArray.begin(); i != jsonArray.end(); ++i) {
            QJsonValue jsonValue = *i;
            QJsonObject item = jsonValue.toObject();
            QStringList keyList = item.keys();

            QList<QString>::iterator j;
            for (j = keyList.begin(); j != keyList.end(); ++j) {
                if(*j == "id") {

                    QString id = item.find(*j).value().toString();
                    if(id == meter_id) {

                        variant = parseObject(item, "dateMeasured");
                        QVariant dateVariant = parseObject(variant.toObject(), "value").toVariant();
                        timestamp = dateVariant.toDateTime();

                        variant = parseObject(item, "measuredValue");
                        value = parseObject(variant.toObject(), "value").toString().toDouble();
                        variant = parseObject(item, "unit");
                        unit = parseObject(variant.toObject(), "value").toString();
                    }

                }

            }
        }
    }

    return true;
}

// Parses an object and returns the value that match the key.
QJsonValue JSONParser::parseObject(QJsonObject object, QString key) {

   QStringList keyList = object.keys();
   QList<QString>::iterator i;
   QJsonValue value;
   for (i = keyList.begin(); i != keyList.end(); ++i) {
       if (*i == key) {
           value = object.find(*i).value();
           break;
       }
   }
   return value;
}



// Returns parsed history data to dataReader.
QVariantList JSONParser::getHistory(QByteArray json_bytes)
{
     QVariantList dateValueList;
     if (json_bytes.isNull()) {
         return dateValueList;
     }

    auto json_doc = QJsonDocument::fromJson(json_bytes);
    QJsonObject jsonObj = json_doc.object();
    QJsonValue contextRes = parseContextResponses(jsonObj);
    QJsonValue contextElem = parseContextElements(contextRes);

    QJsonValue attributes = parseAttributes(contextElem);
    getHistoryValues(dateValueList, attributes);

    return dateValueList;


}

// Parses context responses from history JSON.
QJsonValue JSONParser::parseContextResponses(QJsonObject object)
{
    QStringList keyList = object.keys();
    QList<QString>::iterator i;
    QJsonValue value;
    for (i = keyList.begin(); i != keyList.end(); ++i) {
        if (*i == "contextResponses") {
            value = object.find(*i).value();
            break;
        }
    }
    return value;

}

// Parses context elements from history JSON.
QJsonValue JSONParser::parseContextElements(QJsonValue object)
{
    QJsonValue jsonVal;
    if (object.isArray()) {
        QJsonArray jsonArr = object.toArray();
        jsonVal = jsonArr.at(0);
    }

    QJsonObject jsonObj = jsonVal.toObject();
    QStringList keyList = jsonObj.keys();
    QList<QString>::iterator i;
    QJsonValue value;
    for (i = keyList.begin(); i != keyList.end(); ++i) {
        if (*i == "contextElement") {
            value = jsonObj.find(*i).value();
            break;
        }
    }
    return value;

}

// Parses attributes from history JSON.
QJsonValue JSONParser::parseAttributes(QJsonValue jsonVal)
{
    QJsonObject object = jsonVal.toObject();
    QStringList keyList = object.keys();
    QList<QString>::iterator i;
    QJsonValue value;
    for (i = keyList.begin(); i != keyList.end(); ++i) {
        if (*i == "attributes") {
            value = object.find(*i).value();
            break;
        }
    }
    return value;
}

// Parses values from history JSON.
QJsonValue JSONParser::parseValues(QJsonValue values) {

    QJsonValue jsonVal;
    if (values.isArray()) {
        QJsonArray jsonArr = values.toArray();
        jsonVal = jsonArr.at(0);
    }

    QJsonObject jsonObj = jsonVal.toObject();
    QStringList keyList = jsonObj.keys();
    QList<QString>::iterator i;
    for (i = keyList.begin(); i != keyList.end(); i++) {
        if (*i == "values") {
            jsonVal = jsonObj.find(*i).value();
            break;
        }
    }

    return jsonVal;
}

// Parses individual history values from history JSON and inserts them to 
// the datastruckture.
void JSONParser::getHistoryValues(QVariantList &list, QJsonValue values)
{

    QJsonArray attributesArr;
    if (values.isArray()) {
        attributesArr = values.toArray();
    }

    for (int i = 0; i != attributesArr.size(); ++i) {

        QJsonValue attributesToValue = attributesArr.at(i);
        QJsonObject attributesToObj = attributesToValue.toObject();
        QJsonValue allValues = attributesToObj.find("values").value();

        QJsonArray allValuesArr;
        if (allValues.isArray()) {
            allValuesArr  = allValues.toArray();

            for (int j = 0 ; j != allValuesArr.size(); ++j) {

                QJsonObject singleValueObject = allValuesArr.at(j).toObject();
                
                QVariantMap map;
                
                const QVariant dateVariant = singleValueObject.find("recvTime").value().toVariant();
                const QVariant valueVariant = singleValueObject.find("attrValue").value().toVariant();
                
                const QString timestamp = "timestamp";
                const QString value = "value";
                
                map.insert(timestamp, dateVariant);
                map.insert(value, valueVariant);
                
                list.append(map);

            }
        }

    }


}
