/*
 * Copyright 2020 Eike K. & Contributors
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

package docspell.restserver

import cats.effect._

import docspell.backend.BackendApp
import docspell.common.Logger
import docspell.ftsclient.FtsClient
import docspell.ftssolr.SolrFtsClient
import docspell.pubsub.api.{PubSub, PubSubT}
import docspell.store.Store

import org.http4s.client.Client

final class RestAppImpl[F[_]](val config: Config, val backend: BackendApp[F])
    extends RestApp[F] {}

object RestAppImpl {

  def create[F[_]: Async](
      cfg: Config,
      store: Store[F],
      httpClient: Client[F],
      pubSub: PubSub[F]
  ): Resource[F, RestApp[F]] = {
    val logger = Logger.log4s(org.log4s.getLogger(s"restserver-${cfg.appId.id}"))
    for {
      ftsClient <- createFtsClient(cfg)(httpClient)
      pubSubT = PubSubT(pubSub, logger)
      backend <- BackendApp.create[F](cfg.backend, store, ftsClient, pubSubT)
      app = new RestAppImpl[F](cfg, backend)
    } yield app
  }

  private def createFtsClient[F[_]: Async](
      cfg: Config
  )(client: Client[F]): Resource[F, FtsClient[F]] =
    if (cfg.fullTextSearch.enabled) SolrFtsClient(cfg.fullTextSearch.solr, client)
    else Resource.pure[F, FtsClient[F]](FtsClient.none[F])
}
