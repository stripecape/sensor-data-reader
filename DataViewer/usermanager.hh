#ifndef USERMANAGER_HH
#define USERMANAGER_HH

#include <QObject>

// Reads and writes information regarding the users configuration of dataviews in config-file
class UserManager : public QObject
{
    Q_OBJECT
public:
    explicit UserManager(QObject *parent = nullptr);


public slots:
    void saveConfig(QString config);
    QString getPreviousConfig();
};

#endif // USERMANAGER_HH
