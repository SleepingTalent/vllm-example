#!/bin/bash

minikube_manager() {
  if [ -z "$1" ]; then
    print_error "Usage: minikube_manager {status|start|stop|reset}"
    exit 1
  fi

  case "$1" in
    status)
      print_info "Minikube status..."
      minikube status
      ;;
    start)
      print_info "Starting Minikube..."
      minikube start --cpus=6 --memory=12g --disk-size=40g --driver=docker
      print_info "Setting kubectl context to Minikube..."
      kubectl config use-context minikube
      print_warning "Current kubectl context: $(kubectl config current-context)"
      print_info "Minikube started."
      ;;
    stop)
      print_info "Stopping Minikube..."
      minikube stop
      print_info "Minikube stopped."
      ;;
    reset)
      print_info "Resetting Minikube..."
      minikube delete
      minikube start --cpus=6 --memory=12g --disk-size=40g --driver=docker
      kubectl config use-context minikube
      print_info "Minikube reset and started."
      ;;
    *)
      print_error "Invalid command: $1"
      print_error "Usage: minikube_manager {status|start|stop|reset}"
      exit 1
      ;;
  esac
}
