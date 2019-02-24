#include "dataanalyzer.hh"
#include "datareader.hh"

#include <math.h>
#include <QDateTime>
#include <QDebug>
#include <iomanip>
#include <iostream>

DataAnalyzer::DataAnalyzer(QObject *parent) : QObject(parent) {

}

double DataAnalyzer::getAvg(QVariantList values)
{
       double sum = 0;

       QVariantList::iterator i = values.begin();
       while(i != values.end()){
           sum += (*i).toMap().value("value").toDouble();
           i++;
       }

       return sum / values.length();
}

// Calculates correlation.
double DataAnalyzer::getCorrelation(QVariantList values)
{

    if ( values.empty() ) {
        return 0;
    }

    QVariantList values_x;
    QVariantList values_y;

    for (int i = 0; i < values.size() ; ++i ) {
        QVariantMap map_y;
        QVariantMap map_x;
        map_x.insert("value", values[i].toMap()["x"]);
        map_y.insert("value", values[i].toMap()["y"]);
        values_x.append(map_x);
        values_y.append(map_y);
    }

    double x_avg = getAvg(values_x);
    double y_avg = getAvg(values_y);

    double x_stddev = getStdDeviation(values_x);
    double y_stddev = getStdDeviation(values_y);


    double sum = 0;

    QVariantList::iterator i = values_x.begin();
    QVariantList::iterator j = values_y.begin();
    while(i != values_x.end()){
        double x = (*i).toMap().value("value").toDouble();
        double y = (*j).toMap().value("value").toDouble();
        sum += (x - x_avg)*(y - y_avg);
        i++;
        j++;
    }
    double value = sum /(values_x.length() * x_stddev * y_stddev);
    return value ;
}

// Calculates standard deviation.
double DataAnalyzer::getStdDeviation(QVariantList values)
{
    double avg = getAvg(values);
    double sum = 0;

    QVariantList::iterator i = values.begin();
    while(i != values.end()){
        sum += pow(((*i).toMap().value("value").toDouble() - avg), 2);
        i++;
    }

    if (values.length() > 1){
        return sqrt(sum / values.length());
    }

    return 0;
}

// Connects two datalists in order to compare data.
QVariantList DataAnalyzer::connectData(QVariantList dataListX, QVariantList dataListY)
{

    QVariantList combinedDataList;


    struct sortingStruct
    {
        double x;
        double y;
    };
    std::vector<sortingStruct> sortingvector;

    if ( dataListX.empty() or dataListY.empty() ) {
        return combinedDataList;
    }


    if (dataListX.size() == dataListY.size()) {

        for (int i = 0; i < dataListX.size(); ++i) {
            sortingStruct s;
            QVariantMap mapx = dataListX[i].toMap();
            s.x = mapx["value"].toString().toDouble();
            QVariantMap mapy = dataListY[i].toMap();
            s.y = mapy["value"].toString().toDouble();
            sortingvector.push_back(s);
        }


        std::sort(sortingvector.begin(), sortingvector.end(),
                  [](sortingStruct a, sortingStruct b) {
            return a.x < b.x;
        });

        for (unsigned int i = 0; i < sortingvector.size(); ++i) {
            QVariantMap m;
            m.insert("x", QVariant(QString::number(sortingvector[i].x)));
            m.insert("y", QVariant(QString::number(sortingvector[i].y)));
            combinedDataList.append(m);
        }

        return combinedDataList;

    }


    return combinedDataList;

}



