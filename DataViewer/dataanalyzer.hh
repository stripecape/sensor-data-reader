#ifndef DATAANALYZER_HH
#define DATAANALYZER_HH

#include <QVariantList>
#include <QDateTime>

class DataAnalyzer : public QObject
{
    Q_OBJECT
    public:
        explicit DataAnalyzer(QObject *parent = nullptr);
        Q_INVOKABLE double getAvg(QVariantList values);
        Q_INVOKABLE double getCorrelation(QVariantList values);
        Q_INVOKABLE double getStdDeviation(QVariantList values);
        Q_INVOKABLE QVariantList connectData(QVariantList dataListX, QVariantList dataListY);



};

#endif // DATAANALYZER_HH
