#ifndef JSONPARSER_H
#define JSONPARSER_H
#include <QJsonDocument>
#include <QVariantMap>
#include <QDateTime>


class JSONParser
{
public:
    JSONParser();
    QList<QPair<QString, QString>> getMeters(QByteArray json_bytes);
    bool getCurrentValue(QByteArray json_bytes, QString meter_id, QDateTime &timestamp, double &value, QString &unit);

    QJsonValue parseObject(QJsonObject object, QString key);

    QVariantList getHistory(QByteArray json_bytes);
    QJsonValue parseContextResponses(QJsonObject object);
    QJsonValue parseContextElements(QJsonValue object);
    QJsonValue parseAttributes(QJsonValue jsonVal);
    QJsonValue parseValues(QJsonValue values);
    void getHistoryValues(QVariantList &list, QJsonValue values);

};

#endif // JSONPARSER_H
