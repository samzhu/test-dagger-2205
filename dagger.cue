package main

import (
    "dagger.io/dagger"
    "universe.dagger.io/docker"
)

dagger.#Plan & {
    client: {
        filesystem:{
            // ローカルの現在のディレクトリをコンテナから読み出すRead権限を付与
            "./": read: {
                contents: dagger.#FS
                exclude: [
                    ".gradle",
                    "build",
                    "springtest.cue",
                ]
            }
        }
        network: "unix:///var/run/docker.sock": connect: dagger.#Socket // Docker daemon socket
    }
    actions: {
        deps: docker.#Build & {
            steps: [
                docker.#Pull & {
                    source: "gradle:7.4.2-jdk17" 
                },
                // 現在のディレクトリを実行コンテナにコピーする
                docker.#Copy & {
                    contents: client.filesystem."./".read.contents
                    dest: "/app"
                }
            ]
        }
        // build
        build: {
            run: docker.#Run & {
                input: deps.output
                workdir: "/app"
                mounts: docker: {
                    dest:     "/var/run/docker.sock"
                    contents: client.network."unix:///var/run/docker.sock".connect
                }
                command: {
                    name: "gradle"
                    args: ["--no-daemon", "-x", "test", "clean", "bootBuildImage"]
                }
            }
        }
    }
}