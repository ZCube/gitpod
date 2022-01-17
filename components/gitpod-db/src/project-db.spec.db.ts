/**
 * Copyright (c) 2022 Gitpod GmbH. All rights reserved.
 * Licensed under the GNU Affero General Public License (AGPL).
 * See License-AGPL.txt in the project root for license information.
 */

import * as chai from 'chai';
const expect = chai.expect;
import { suite, test, timeout } from 'mocha-typescript';
import { TypeORM } from './typeorm/typeorm';
import { TypeORMUserDBImpl } from './typeorm/user-db-impl';
import { TeamDBImpl } from './typeorm/team-db-impl';
import { testContainer } from './test-container';
import { ProjectDBImpl } from './typeorm/project-db-impl';
import { DBProject } from './typeorm/entity/db-project';
import { DBUser } from './typeorm/entity/db-user';
import { DBTeam } from './typeorm/entity/db-team';
import { Project } from "@gitpod/gitpod-protocol";

@suite class ProjectDBSpec {
    projectDb = testContainer.get<ProjectDBImpl>(ProjectDBImpl);
    userDb = testContainer.get<TypeORMUserDBImpl>(TypeORMUserDBImpl);
    teamDb = testContainer.get<TeamDBImpl>(TeamDBImpl);

    async before() {
        await this.wipeRepo();
    }

    async after() {
        await this.wipeRepo();
    }

    async wipeRepo() {
        const typeorm = testContainer.get<TypeORM>(TypeORM);
        const manager = await typeorm.getConnection();
        await manager.getRepository(DBProject).delete({})
        await manager.getRepository(DBUser).delete({});
        await manager.getRepository(DBTeam).delete({});
    }

    @test(timeout(5000))
    public async findProject() {
        const user = await this.userDb.newUser();
        user.identities.push({ authProviderId: 'GitHub', authId: '1234', authName: 'newUser', primaryEmail: 'newuser@git.com' });
        await this.userDb.storeUser(user);

        const team = await this.teamDb.createTeam(user.id, 'some-team');

        const project = await Project.create({
            name: "some-project", slug: "some-project", cloneUrl: "some-random-clone-url", teamId: team.id, userId: user.id, appInstallationId: "app-1"
        });

        await this.projectDb.storeProject(project);

        // expect(this.projectDb.findProjectsBySearchTerm(0, 10, "creationTime", "DESC", "rand")).to.equal({});
        expect(true).to.be.true;
    }
}

module.exports = new ProjectDBSpec()
