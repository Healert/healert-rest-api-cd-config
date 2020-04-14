function(
  containerPort=4000,
  image='enyachoke/healert-rest-api:build-d261c58',
  name='healert-rest-api',
  replicas=1,
  servicePort=4000,
  type='ClusterIP',
  mongo_url='mongodb://localhost:27017/healert',
  ingressHost='healert-rest-api.emmanuelnyachoke.com'
)
  [
    {
      apiVersion: 'v1',
      kind: 'Service',
      metadata: {
        name: name,
      },
      spec: {
        ports: [
          {
            port: servicePort,
            targetPort: containerPort,
          },
        ],
        selector: {
          app: name,
        },
        type: type,
      },
    },
    {
      apiVersion: 'apps/v1',
      kind: 'Deployment',
      metadata: {
        name: name,
      },
      spec: {
        replicas: replicas,
        revisionHistoryLimit: 3,
        selector: {
          matchLabels: {
            app: name,
          },
        },
        template: {
          metadata: {
            labels: {
              app: name,
            },
          },
          spec: {
            volumes: [
              {
                name: 'firebase-config-data',
                configMap: {
                  name: 'firebase-config-config',
                },
              },
            ],
            containers: [
              {
                image: image,
                name: name,
                volumeMounts: [
                  {
                    name: 'firebase-config-data',
                    mountPath: '/home/node/app/config/service-account-file.json',
                    subPath: "service-account-file.json"
                  },
                ],
                env: [
                  {
                    name: 'MONGO_URL',
                    value: mongo_url,
                  },
                  {
                    name: 'TZ',
                    value: "Africa/Nairobi",
                  },
                ],
                ports: [
                  {
                    containerPort: containerPort,
                  },
                ],
              },
            ],
          },
        },
      },
    },
    {
      apiVersion: 'extensions/v1beta1',
      kind: 'Ingress',
      metadata: {
        annotations: {
          'ingress.kubernetes.io/proxy-body-size': '500m',
          'kubernetes.io/ingress.class': 'nginx',
          'nginx.ingress.kubernetes.io/force-ssl-redirect': 'true',
          'nginx.ingress.kubernetes.io/proxy-body-size': '500m',
          'cert-manager.io/cluster-issuer': 'letsencrypt-prod',
        },
        labels: {
          app: name,
        },
        name: name,
      },
      spec: {
        tls: [
          {
            hosts: [
              ingressHost,
            ],
            secretName: name + '-tls',
          },
        ],
        rules: [
          {
            host: ingressHost,
            http: {
              paths: [
                {
                  backend: {
                    serviceName: name,
                    servicePort: containerPort,
                  },
                  path: '/',
                },
              ],
            },
          },
        ],
      },
    },
  ]
