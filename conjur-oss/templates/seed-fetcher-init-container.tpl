{{- /*
  Defined here: "seedfetcherInitContainerVolumes" and "seedfetcherInitContainer"
  Both are required for init container to work
*/ -}}

{{- define "seedfetcherInitContainerVolumes" }}
- name: {{ .Release.Name }}-conjur-api-token
  emptyDir:
    medium: Memory
- name: {{ .Release.Name }}-conjur-seedfile
  emptyDir:
    medium: Memory
{{ end -}}

{{- define "seedfetcherInitContainer" -}}
- name: seed-fetcher
  image: "{{ .Values.seedService.image.repository }}:{{ .Values.seedService.image.tag }}"
  imagePullPolicy: {{ .Values.seedService.image.pullPolicy }}
  env:
    - name: AUTHENTICATOR_ID
      value: {{ .Values.seedService.authenticatorId }}
    - name: CONJUR_ACCOUNT
      value: {{ .Values.account }}
    - name: CONJUR_SSL_CERTIFICATE
      valueFrom:
        configMapKeyRef:
          name: {{ .Release.Name }}-conjur-seedservice-master-cert
          key: master_cert
    - name: FOLLOWER_HOSTNAME
      value: {{ template "conjur-oss.fullname" . }}
    - name: MASTER_HOSTNAME
      value: {{ .Values.seedService.host }}
    - name: SEEDFILE_DIR
      value: /tmp/seedfile

    - name: MY_POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: MY_POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: MY_POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP

  volumeMounts:
    - name: {{ .Release.Name }}-conjur-api-token
      mountPath: /run/conjur
    - name: {{ .Release.Name }}-conjur-seedfile
      mountPath: /tmp/seedfile
{{ end -}}